module Bucky
  # An exception which is not a cause for a web request to fail, tell airbrake or whoever, but continue as normal
  class NonFatalException < Exception
  end
end
