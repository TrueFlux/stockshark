STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

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
end
