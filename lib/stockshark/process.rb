require "open3"

module Stockshark
  # Raw OS process lifecycle for a UCI-speaking engine — spawns it, writes
  # lines to its stdin, and continuously drains stdout *and* stderr from
  # dedicated reader threads so neither pipe can ever fill up and block the
  # child. Draining stderr matters here specifically because the engine
  # path is operator-configurable: nothing guarantees the binary behind it
  # is a "pure" build that never writes to stderr, and if it did while
  # nobody was reading that pipe, the child would block writing to it and
  # every read on stdout would hang right along with it.
  #
  # Zero chess/UCI knowledge on purpose — Engine owns the protocol, this
  # only owns "a subprocess and its pipes."
  class Process
    def initialize(path)
      @stdin, stdout, stderr, @wait_thread = Open3.popen3(path)
      @queue = Queue.new
      @readers = [ reader_thread(stdout, :stdout), reader_thread(stderr, :stderr) ]
    rescue Errno::ENOENT, Errno::EACCES => e
      raise Stockshark::EngineNotFoundError, "could not start engine at #{path.inspect}: #{e.message}"
    end

    def write_line(line)
      raise Stockshark::CrashedError, "engine process is not running" unless alive?

      @stdin.puts(line)
    rescue Errno::EPIPE, IOError => e
      raise Stockshark::CrashedError, "could not write to engine: #{e.message}"
    end

    # Pops the next available line from either stream, tagged with which
    # one it came from, waiting at most `timeout` seconds. Returns nil on
    # timeout — never raises Timeout::Error, deliberately: cancellation
    # here is just "give up waiting on the queue," not "interrupt whatever
    # is actually blocking," which is what makes Ruby's Timeout.timeout
    # unsafe to wrap around real IO.
    def read_line(timeout:)
      @queue.pop(timeout: timeout)
    end

    def alive?
      @wait_thread.alive?
    end

    # Safe to call more than once, and safe to call after the process has
    # already died on its own.
    def stop
      return unless alive?

      begin
        @stdin.puts("quit")
      rescue Errno::EPIPE, IOError
        # already gone — nothing left to say goodbye to.
      end

      unless @wait_thread.join(0.5)
        ::Process.kill("KILL", @wait_thread.pid)
        @wait_thread.join
      end
    ensure
      @readers.each(&:kill)
      @stdin.close unless @stdin.closed?
    end

    private

    def reader_thread(io, tag)
      Thread.new do
        loop do
          line = io.gets
          break if line.nil?

          @queue << { stream: tag, line: line.chomp }
        end
      rescue IOError
        # stream closed out from under us during shutdown — fine.
      end
    end
  end
end
