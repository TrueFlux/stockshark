require_relative "stockshark/version"
require_relative "stockshark/error"
require_relative "stockshark/engine_not_found_error"
require_relative "stockshark/timeout_error"
require_relative "stockshark/crashed_error"
require_relative "stockshark/configuration"
require_relative "stockshark/process"
require_relative "stockshark/uci_protocol"
require_relative "stockshark/engine"

# Stockshark::Engine talks to a UCI chess engine (Stockfish, or anything
# else that speaks the protocol) over stdin/stdout/stderr pipes. Plain Ruby,
# stdlib only (Open3) — no chess rules engine, no board representation, no
# opinions about evaluation perspective or move classification, so it stays
# usable by anything that just needs "FEN in, evaluation out" regardless of
# what it's built on top of. No autoloader here (unlike when this lived
# inside a Rails app under Zeitwerk), so every file is required explicitly
# above, in dependency order.
module Stockshark
end
