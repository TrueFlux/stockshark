module Stockshark
  # The public façade for talking to a UCI engine — the only class most
  # callers should ever need to touch. Hides process management (Process)
  # and protocol parsing (UciProtocol) entirely: callers only ever see
  # "give me a FEN and a depth/movetime, get back an evaluation."
  class Engine
    # One multipv rank's worth of a search result: its own score (exactly
    # one of score_cp/score_mate is ever set, matching UCI itself — an
    # engine never reports both for the same line) and principal variation.
    Line = Struct.new(:multipv, :score_cp, :score_mate, :pv, keyword_init: true)

    # The full result of one #analyze call: the move the engine would
    # actually play, the deepest ply reached, and one Line per multipv
    # rank requested (ranks are 1-indexed and sorted, so lines.first is
    # always the primary/best line). Raw and side-to-move-relative —
    # unopinionated about which color that was.
    AnalysisResult = Struct.new(:best_move, :depth, :lines, keyword_init: true)

    attr_reader :name

    def initialize(configuration = Stockshark::Configuration.new, process: nil)
      @configuration = configuration
      @process = process || Stockshark::Process.new(configuration.path)
      @multipv = 1
      handshake
    end

    def analyze(fen:, depth: nil, movetime_ms: nil, multipv: 1)
      raise ArgumentError, "must give depth or movetime_ms" unless depth || movetime_ms

      set_multipv(multipv)
      send_line("position fen #{fen}")
      send_line(depth ? "go depth #{depth}" : "go movetime #{movetime_ms}")

      collect_result(search_timeout(movetime_ms))
    end

    # Safe to call more than once, and safe to call even if the engine was
    # never fully brought up (e.g. handshake itself failed).
    def quit
      @process.stop
    end

    private

    def handshake
      send_line("uci")
      await("uciok") { |message| @name = Stockshark::UciProtocol.parse_id(message)&.fetch(:name) || @name }

      send_line("setoption name Threads value #{@configuration.threads}")
      send_line("setoption name Hash value #{@configuration.hash_mb}")
      send_line("isready")
      await("readyok")

      send_line("ucinewgame")
    end

    def set_multipv(multipv)
      return if multipv == @multipv

      send_line("setoption name MultiPV value #{multipv}")
      @multipv = multipv
    end

    def send_line(line)
      @process.write_line(line)
    end

    # Reads lines (via the configured handshake timeout) until `stop_line`
    # is seen, yielding every line along the way so the caller can pick up
    # anything useful (like "id name ...") that appears before it.
    def await(stop_line)
      deadline = Time.now + (@configuration.max_analyze_ms / 1000.0)
      loop do
        message = read(deadline)
        yield message if block_given?
        return if message == stop_line
      end
    end

    def collect_result(timeout)
      deadline = Time.now + timeout
      latest_by_rank = {}
      max_depth = 0

      loop do
        message = read(deadline)

        if (info = Stockshark::UciProtocol.parse_info(message))
          latest_by_rank[info[:multipv]] = info
          max_depth = [ max_depth, info[:depth] ].max
        elsif (best = Stockshark::UciProtocol.parse_bestmove(message))
          lines = latest_by_rank.sort.map do |_, info|
            Line.new(multipv: info[:multipv], score_cp: info[:score_cp], score_mate: info[:score_mate], pv: info[:pv])
          end
          return AnalysisResult.new(best_move: best[:best_move], depth: max_depth, lines: lines)
        end
      end
    end

    # Blocks until a line arrives on stdout or `deadline` passes, skipping
    # (but not erroring on) stderr activity — Process already drains it
    # continuously in the background, this just isn't interested in its
    # content, only in not being blocked by it.
    def read(deadline)
      loop do
        remaining = deadline - Time.now
        raise Stockshark::TimeoutError, "engine did not respond in time" if remaining <= 0
        raise Stockshark::CrashedError, "engine process exited unexpectedly" unless @process.alive?

        entry = @process.read_line(timeout: remaining)
        next if entry.nil?
        next if entry[:stream] == :stderr

        return entry[:line]
      end
    end

    def search_timeout(movetime_ms)
      base = movetime_ms ? movetime_ms / 1000.0 : 0
      base + (@configuration.max_analyze_ms / 1000.0)
    end
  end
end
