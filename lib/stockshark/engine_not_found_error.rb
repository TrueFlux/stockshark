module Stockshark
  # The configured engine binary doesn't exist, isn't executable, or
  # couldn't be spawned for some other OS-level reason.
  class EngineNotFoundError < Error; end
end
