describe Stockshark::UciProtocol do
  describe ".parse_id" do
    it "extracts the engine name from an id name line" do
      expect(described_class.parse_id("id name Stockfish 16")).to eq(name: "Stockfish 16")
    end

    it "returns nil for an id author line" do
      expect(described_class.parse_id("id author the Stockfish developers")).to be_nil
    end

    it "returns nil for an unrelated line" do
      expect(described_class.parse_id("uciok")).to be_nil
    end
  end

  describe ".parse_bestmove" do
    it "parses a bestmove with a ponder move" do
      expect(described_class.parse_bestmove("bestmove e2e4 ponder e7e5")).to eq(best_move: "e2e4", ponder: "e7e5")
    end

    it "parses a bestmove with no ponder move" do
      expect(described_class.parse_bestmove("bestmove e2e4")).to eq(best_move: "e2e4", ponder: nil)
    end

    it "returns nil for a non-bestmove line" do
      expect(described_class.parse_bestmove("info depth 1")).to be_nil
    end
  end

  describe ".parse_info" do
    it "parses a centipawn score line" do
      line = "info depth 20 seldepth 28 multipv 1 score cp 34 nodes 12345 pv e2e4 e7e5 g1f3"

      expect(described_class.parse_info(line)).to eq(
        depth: 20, multipv: 1, score_cp: 34, score_mate: nil, pv: %w[e2e4 e7e5 g1f3]
      )
    end

    it "parses a mate score line, including a negative (losing) mate" do
      line = "info depth 12 multipv 2 score mate -3 pv d1d8 e8d8"

      expect(described_class.parse_info(line)).to eq(
        depth: 12, multipv: 2, score_cp: nil, score_mate: -3, pv: %w[d1d8 e8d8]
      )
    end

    it "defaults multipv to 1 when the engine omits it" do
      line = "info depth 5 score cp 10 pv e2e4"

      expect(described_class.parse_info(line)[:multipv]).to eq(1)
    end

    it "returns nil for a line with no score at all" do
      expect(described_class.parse_info("info string NNUE evaluation enabled")).to be_nil
    end

    it "returns nil for a currmove progress line" do
      expect(described_class.parse_info("info currmove e2e4 currmovenumber 1")).to be_nil
    end

    it "parses a checkmate position's score line, which carries no pv" do
      expect(described_class.parse_info("info depth 0 score mate 0")).to eq(
        depth: 0, multipv: 1, score_cp: nil, score_mate: 0, pv: []
      )
    end

    it "parses a stalemate position's score line, which also carries no pv" do
      expect(described_class.parse_info("info depth 0 score cp 0")).to eq(
        depth: 0, multipv: 1, score_cp: 0, score_mate: nil, pv: []
      )
    end
  end
end
