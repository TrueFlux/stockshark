describe Stockshark::Engine do
  let(:configuration) { Stockshark::Configuration.new(path: "fake", threads: 2, hash_mb: 64, max_analyze_ms: 20) }

  def line(text, stream: :stdout)
    { stream: stream, line: text }
  end

  def build_engine(process)
    described_class.new(configuration, process: process)
  end

  describe "#initialize (handshake)" do
    let(:process) do
      FakeProcess.new(lines: [
        line("id name Stockfish 16"),
        line("id author the Stockfish developers", stream: :stderr),
        line("uciok"),
        line("readyok")
      ])
    end
    let(:engine) { build_engine(process) }

    it "captures the engine's reported name from the id name line" do
      expect(engine.name).to eq("Stockfish 16")
    end

    it "sends uci, isready, and ucinewgame" do
      engine
      expect(process.written).to include("uci", "isready", "ucinewgame")
    end

    it "configures threads and hash from the given configuration" do
      engine
      expect(process.written).to include("setoption name Threads value 2", "setoption name Hash value 64")
    end
  end

  describe "#analyze" do
    let(:process) do
      FakeProcess.new(lines: [
        line("id name Stockfish 16"), line("uciok"), line("readyok"),
        *analyze_lines
      ])
    end
    let(:engine) { build_engine(process) }

    context "with a single principal variation" do
      let(:analyze_lines) do
        [
          line("info depth 10 currmove e2e4 currmovenumber 1", stream: :stdout),
          line("info depth 18 multipv 1 score cp 34 nodes 999 pv e2e4 e7e5", stream: :stderr),
          line("info depth 18 multipv 1 score cp 34 nodes 999 pv e2e4 e7e5"),
          line("bestmove e2e4 ponder e7e5")
        ]
      end
      let(:result) { engine.analyze(fen: "startpos", depth: 18) }

      it "sends the position and a depth-based go command" do
        result
        expect(process.written).to include("position fen startpos", "go depth 18")
      end

      it "returns the engine's chosen best move" do
        expect(result.best_move).to eq("e2e4")
      end

      it "returns the deepest depth reached" do
        expect(result.depth).to eq(18)
      end

      it "returns one line with the score and principal variation" do
        expect(result.lines.size).to eq(1)
        expect(result.lines.first).to have_attributes(multipv: 1, score_cp: 34, score_mate: nil, pv: %w[e2e4 e7e5])
      end
    end

    context "with movetime instead of depth" do
      let(:analyze_lines) { [ line("info depth 5 multipv 1 score cp 10 pv e2e4"), line("bestmove e2e4") ] }

      it "sends a movetime-based go command instead of depth" do
        engine.analyze(fen: "startpos", movetime_ms: 500)
        expect(process.written).to include("go movetime 500")
      end
    end

    context "with multipv > 1" do
      let(:analyze_lines) do
        [
          line("info depth 15 multipv 2 score cp 10 pv d2d4 d7d5"),
          line("info depth 15 multipv 1 score mate 3 pv e2e4 e7e5 f1c4"),
          line("bestmove e2e4")
        ]
      end

      it "requests MultiPV from the engine" do
        engine.analyze(fen: "startpos", depth: 15, multipv: 2)
        expect(process.written).to include("setoption name MultiPV value 2")
      end

      it "returns lines sorted by rank regardless of arrival order" do
        result = engine.analyze(fen: "startpos", depth: 15, multipv: 2)
        expect(result.lines.map(&:multipv)).to eq([ 1, 2 ])
      end

      it "captures a mate score distinctly from a centipawn score" do
        result = engine.analyze(fen: "startpos", depth: 15, multipv: 2)
        expect(result.lines.first).to have_attributes(score_cp: nil, score_mate: 3)
      end

      it "does not resend MultiPV on a later call with the same value" do
        two_batches = FakeProcess.new(lines: [
          line("id name Stockfish 16"), line("uciok"), line("readyok"),
          *analyze_lines, *analyze_lines
        ])
        two_call_engine = build_engine(two_batches)

        two_call_engine.analyze(fen: "startpos", depth: 15, multipv: 2)
        two_batches.written.clear
        two_call_engine.analyze(fen: "startpos", depth: 15, multipv: 2)

        expect(two_batches.written).not_to include(a_string_matching(/MultiPV/))
      end
    end

    it "requires either a depth or a movetime" do
      bare_process = FakeProcess.new(lines: [ line("id name Stockfish 16"), line("uciok"), line("readyok") ])
      bare_engine = build_engine(bare_process)

      expect { bare_engine.analyze(fen: "startpos") }.to raise_error(ArgumentError)
    end
  end

  describe "timing out" do
    let(:process) { FakeProcess.new(lines: [ line("id name SF"), line("uciok"), line("readyok") ]) }
    let(:engine) { build_engine(process) }

    it "raises Stockshark::TimeoutError when the engine never responds within the configured deadline" do
      expect { engine.analyze(fen: "startpos", depth: 18) }.to raise_error(Stockshark::TimeoutError)
    end
  end

  describe "the engine process crashing mid-search" do
    let(:process) do
      FakeProcess.new(
        lines: [ line("id name SF"), line("uciok"), line("readyok"), line("info depth 1 score cp 0 pv e2e4") ],
        crash_after: 4
      )
    end
    let(:engine) { build_engine(process) }

    it "raises Stockshark::CrashedError instead of hanging" do
      expect { engine.analyze(fen: "startpos", depth: 18) }.to raise_error(Stockshark::CrashedError)
    end
  end

  describe "#quit" do
    let(:process) { FakeProcess.new(lines: [ line("id name SF"), line("uciok"), line("readyok") ]) }
    let(:engine) { build_engine(process) }

    it "stops the underlying process" do
      engine.quit
      expect(process.alive?).to be false
    end

    it "is safe to call more than once" do
      engine.quit
      expect { engine.quit }.not_to raise_error
    end
  end
end
