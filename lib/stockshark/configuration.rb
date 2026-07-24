module Stockshark
  # Environment-driven configuration — nothing here is ever a hardcoded,
  # machine-specific path. Every value has a sensible default so the
  # library works out of the box locally, but production is expected to
  # set these explicitly (particularly STOCKFISH_PATH, since "stockfish"
  # resolving via $PATH isn't guaranteed on every deploy target). Env var
  # names stay STOCKFISH_* (not STOCKSHARK_*) deliberately — they configure
  # the actual Stockfish (or Stockfish-compatible) binary being launched,
  # which is a separate thing from what this gem happens to be called.
  class Configuration
    attr_accessor :path, :threads, :hash_mb, :max_analyze_ms

    def initialize(
      path: ENV.fetch("STOCKFISH_PATH", "stockfish"),
      threads: Integer(ENV.fetch("STOCKFISH_THREADS", 1)),
      hash_mb: Integer(ENV.fetch("STOCKFISH_HASH", 16)),
      max_analyze_ms: Integer(ENV.fetch("STOCKFISH_MAX_ANALYZE_MS", 30_000))
    )
      @path = path
      @threads = threads
      @hash_mb = hash_mb
      @max_analyze_ms = max_analyze_ms
    end
  end
end
