module Stockshark
  # The engine didn't respond within the configured deadline — either a
  # genuinely wedged search, or a process that's alive but not speaking
  # UCI back (e.g. an unexpected build writing diagnostics to stderr and
  # never reaching readyok/bestmove on stdout).
  class TimeoutError < Error; end
end
