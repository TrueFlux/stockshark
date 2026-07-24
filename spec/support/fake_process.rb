# A hand-rolled double standing in for Stockshark::Process (real OS
# subprocess + pipes) in Engine specs, so those specs can script exact UCI
# responses without a real engine binary installed. Mirrors Process's
# actual contract: #read_line blocks (via sleep here, same as
# Queue#pop(timeout:) really would) once queued lines run out, rather than
# returning nil immediately — that's what lets a real timeout spec
# exercise Engine's actual deadline math instead of a shortcut.
class FakeProcess
  attr_reader :written

  def initialize(lines: [], crash_after: nil)
    @lines = lines.dup
    @crash_after = crash_after
    @reads = 0
    @alive = true
    @written = []
  end

  def write_line(line)
    raise Stockshark::CrashedError, "engine process is not running" unless @alive

    @written << line
  end

  def read_line(timeout:)
    if @lines.empty?
      sleep([ timeout, 0 ].max)
      return nil
    end

    @reads += 1
    @alive = false if @crash_after && @reads >= @crash_after
    @lines.shift
  end

  def alive?
    @alive
  end

  def stop
    @alive = false
  end
end
