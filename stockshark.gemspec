require_relative 'lib/stockshark/version'

Gem::Specification.new do |spec|
  spec.name = 'stockshark'
  spec.version = Stockshark::VERSION
  spec.authors = [ 'Phil Brockwell' ]
  spec.email = [ 'phil@trueflux.agency' ]

  spec.summary = 'A small, dependency-free Ruby wrapper for talking to a UCI chess engine.'
  spec.description = <<~DESC
    Stockshark drives any UCI-speaking chess engine (Stockfish, or anything
    else that implements the protocol) over stdin/stdout/stderr pipes: start
    it, hand it a FEN, get back a structured evaluation (centipawns or mate
    score, best move, principal variation, depth reached). No chess rules
    engine, no board representation, no opinions about perspective or move
    classification — just the UCI protocol, cleanly wrapped.
  DESC
  spec.homepage = 'https://github.com/TrueFlux/stockshark'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
                  .reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  spec.require_paths = [ 'lib' ]
end
