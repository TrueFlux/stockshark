module Stockshark
  # Pure parsing of UCI protocol text into structured Ruby data. No IO, no
  # process — every method here is a plain string in, hash/nil out, which
  # is what makes it trivially unit-testable without ever spawning a real
  # engine. Scores are returned exactly as the engine reports them:
  # relative to whichever side is to move in the position that was
  # analyzed. Flipping that to a fixed perspective is a game-aware decision
  # this module deliberately knows nothing about — that's up to whatever
  # calls this gem.
  module UciProtocol
    module_function

    # "id name Stockfish 16" => { name: "Stockfish 16" }
    # "id author ..." and any other id line => nil (not what we need).
    def parse_id(line)
      match = line.match(/\Aid name (?<name>.+)\z/)
      return nil unless match

      { name: match[:name] }
    end

    # "bestmove e2e4 ponder e7e5" => { best_move: "e2e4", ponder: "e7e5" }
    def parse_bestmove(line)
      match = line.match(/\Abestmove (?<best_move>\S+)(?: ponder (?<ponder>\S+))?/)
      return nil unless match

      { best_move: match[:best_move], ponder: match[:ponder] }
    end

    # "info depth 20 seldepth 28 multipv 1 score cp 34 nodes 12345 pv e2e4 e7e5 g1f3"
    #   => { depth: 20, multipv: 1, score_cp: 34, score_mate: nil, pv: ["e2e4", "e7e5", "g1f3"] }
    # "info depth 12 multipv 2 score mate -3 pv ... "
    #   => { depth: 12, multipv: 2, score_cp: nil, score_mate: -3, pv: [...] }
    # "info depth 0 score mate 0" (position has no legal moves — checkmate;
    # stalemate reports "score cp 0" instead — neither carries a pv, since
    # there's no move to report)
    #   => { depth: 0, multipv: 1, score_cp: nil, score_mate: 0, pv: [] }
    # Returns nil for info lines that don't carry a score at all (plain
    # "info string ..." diagnostics, "info currmove ...", etc.) — callers
    # should just skip those.
    def parse_info(line)
      return nil unless line.start_with?("info ") && line.match?(/\bscore (?:cp|mate) -?\d+/)

      depth = line[/\bdepth (\d+)/, 1]
      return nil unless depth

      pv = line[/ pv (.+)\z/, 1]

      {
        depth: depth.to_i,
        multipv: (line[/\bmultipv (\d+)/, 1] || "1").to_i,
        score_cp: line[/\bscore cp (-?\d+)/, 1]&.to_i,
        score_mate: line[/\bscore mate (-?\d+)/, 1]&.to_i,
        pv: pv ? pv.split(" ") : []
      }
    end
  end
end
