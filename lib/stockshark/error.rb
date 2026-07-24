module Stockshark
  # Base class for every error this library raises. Callers that only care
  # that "something went wrong talking to the engine" can rescue this one
  # class rather than enumerate every specific failure mode.
  class Error < StandardError; end
end
