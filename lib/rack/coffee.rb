require 'time'
require 'rack/file'
require 'rack/utils'

module Rack
  class Coffee
    F = ::File
    
    attr_accessor :urls, :root
    DEFAULTS = {:static => true}
    
    def initialize(app, opts={})
      opts = DEFAULTS.merge(opts)
      @app = app
      @urls = *opts[:urls] || '/javascripts'
      @root = opts[:root] || Dir.pwd
      @server = opts[:static] ? Rack::File.new(root) : app
      @cache = opts[:cache]
      @ttl = opts[:ttl] || 86400
      @command = ['coffee', '-p']
      @command.push('--no-wrap') if opts[:nowrap]
      @command = @command.join(' ')
    end
    
    def brew(coffee)
      `#{@command} #{coffee}`
    end
    
    def call(env)
      path = Utils.unescape(env["PATH_INFO"])
      return [403, {"Content-Type" => "text/plain"}, ["Forbidden\n"]] if path.include?('..')
      return @app.call(env) unless urls.any?{|url| path.index(url) == 0} and (path =~ /\.js$/)
      javascript = F.join(root, path)
      coffee = F.join(root, path.sub(/\.js$/,'.coffee'))

      if F.file?(coffee)
        contents = brew(coffee)
        if !F.exists?(javascript) || F.mtime(javascript) < F.mtime(coffee)
          F.delete(javascript) if F.exists?(javascript)
          F.open(javascript, 'wb') { |f| f.write( contents ) }
        end
        @server.call(env)
      else
        @server.call(env)
      end
    end
  end
end
