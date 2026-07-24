# Stockshark

A small, dependency-free Ruby wrapper for talking to a UCI-speaking chess
engine (Stockfish, or anything else that implements the protocol) over
stdin/stdout/stderr pipes: start it, hand it a FEN, get back a structured
evaluation (centipawns or mate score, best move, principal variation, depth
reached). No chess rules engine, no board representation, no opinions about
perspective or move classification — just the UCI protocol, cleanly
wrapped.

## Installation

```
bundle add stockshark
```

Or add it to your Gemfile directly:

```ruby
gem "stockshark"
```

## Usage

```ruby
engine = Stockshark::Engine.new
result = engine.analyze(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", depth: 18)

result.best_move        # => "e2e4"
result.depth            # => 18
result.lines.first.pv   # => ["e2e4", "e7e5"]
engine.quit
```

Pass `movetime_ms:` instead of `depth:` for a time-bounded search, and
`multipv:` to get more than one ranked line back (`result.lines` is sorted
by rank, so `lines.first` is always the primary line).

## Configuration

```ruby
configuration = Stockshark::Configuration.new(threads: 4, hash_mb: 128)
engine = Stockshark::Engine.new(configuration)
```

Every option also has an environment variable default (see
`lib/stockshark/configuration.rb`) — deliberately named `STOCKFISH_*`, not
`STOCKSHARK_*`, since they configure the actual engine binary being
launched rather than this library:

- **`STOCKFISH_PATH`** (default `stockfish`) — path to the engine binary,
  resolved via `$PATH` if not absolute.
- **`STOCKFISH_THREADS`** (default `1`) — UCI `Threads`.
- **`STOCKFISH_HASH`** (default `16`) — UCI `Hash`, transposition table
  size in MB.
- **`STOCKFISH_MAX_ANALYZE_MS`** (default `30000`) — how long the engine
  is given to respond before `Stockshark::TimeoutError` is raised.

## Errors

All raised errors descend from `Stockshark::Error`:

- `Stockshark::EngineNotFoundError` — the configured binary doesn't exist,
  isn't executable, or couldn't be spawned.
- `Stockshark::TimeoutError` — the engine didn't respond within the
  configured deadline.
- `Stockshark::CrashedError` — the engine process exited mid-conversation.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then:

```
bundle exec rspec                 # fake-engine suite, no binary required
bundle exec rspec --tag stockfish  # also runs the real-engine integration spec
```

The `--tag stockfish` run needs an actual Stockfish binary on `$PATH` (or
pointed to via `STOCKFISH_PATH`) — it's skipped automatically otherwise
(see `spec/support/stockfish_availability.rb`). Install one with:

```
brew install stockfish        # macOS
apt install stockfish         # Debian/Ubuntu
```

or download a build from [stockfishchess.org/download](https://stockfishchess.org/download).

Lint with:

```
bundle exec rubocop
```

CI (`.github/workflows/ci.yml`) runs both the test suite and RuboCop on
every push and pull request.

Run `bin/console` for an interactive prompt with the gem already loaded.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, bump the version in
`lib/stockshark/version.rb`, then run `bundle exec rake release`, which
tags the version, pushes the commit and tag, and pushes the `.gem` file to
rubygems.org.

## License

MIT — see `LICENSE.txt`.

---

Built by [TrueFlux](https://trueflux.agency).
