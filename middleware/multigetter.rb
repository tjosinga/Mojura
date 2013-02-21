module Mojura

  class MultiGetter

    def initialize(app)
      @app = app
    end

    def call(env)
      if env['PATH_INFO'] == '/multiget'
        req = Rack::Request.new(env)
        body = {}
        queries = req.params['queries']
        queries.each do | retid, query |
          query = retid if query.nil?
          env['PATH_INFO'] = query
          env['MULTIGET'] = 'true'
          status, _, body_part = @app.call(env)
          body[retid] = body_part if status == 200
        end
        headers = {}
        headers['Content-Type'] = 'application/json'
        result = [200, headers, body]
      else
        result = @app.call(env)
      end
      return result
    end
  end

end