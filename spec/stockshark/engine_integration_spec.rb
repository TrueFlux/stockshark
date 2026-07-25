STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
# Fool's mate — Black just delivered checkmate, White has no legal moves.
CHECKMATE_FEN = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"

# Runs against a real Stockfish process — automatically skipped unless one
# is actually available (see spec/support/stockfish_availability.rb),
# since the rest of the suite must never depend on that. Run explicitly
# with `bundle exec rspec --tag stockfish` once a binary is installed.
describe Stockshark::Engine, :stockfish do
  it "completes a real UCI handshake and analyzes the starting position" do
    engine = described_class.new
    result = engine.analyze(fen: STARTING_FEN, depth: 8)

    expect(engine.name).to be_a(String)
    expect(result.best_move).to match(/\A[a-h][1-8][a-h][1-8][qrbn]?\z/)
    expect(result.depth).to be >= 1
    expect(result.lines.first.score_cp || result.lines.first.score_mate).not_to be_nil
  ensure
    engine&.quit
  end

  # Regression: a real checkmated position gets "info depth 0 score mate 0"
  # with no principal variation at all, since there's no move to report —
  # a shape UciProtocol.parse_info used to silently drop, leaving #analyze
  # returning an empty lines array instead of the one scored (but move-
  # less) line a caller needs to tell "no legal moves" from "search failed."
  it "still returns a scored line for a position with no legal moves" do
    engine = described_class.new
    result = engine.analyze(fen: CHECKMATE_FEN, depth: 8)

    expect(result.best_move).to eq("(none)")
    expect(result.lines.size).to eq(1)
    expect(result.lines.first.score_mate).to eq(0)
  ensure
    engine&.quit
  end
end
