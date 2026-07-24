# Lets the small real-binary integration suite (tagged :stockfish) skip
# itself automatically when no actual Stockfish executable is available —
# the normal suite must never depend on one being installed.
module StockfishAvailability
  def self.binary_available?
    path = ENV.fetch("STOCKFISH_PATH", "stockfish")
    return File.executable?(path) if path.include?("/")

    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, path)) }
  end
end

RSpec.configure do |config|
  config.before(:each, :stockfish) do
    skip "no Stockfish binary found (set STOCKFISH_PATH, or install stockfish on PATH)" unless StockfishAvailability.binary_available?
  end
end
