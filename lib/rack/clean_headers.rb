module Rack
  class CleanHeaders
    def initialize(app, options = {})
      @app, @options = app, options
    end

    def call(env)
      response = @app.call(env)

      %w(X-Request-Id X-Runtime X-Rack-Cache X-Powered-By Server).each do |header|
        response[1].delete header # second item is the headers
      end

      response
    end
  end
end
