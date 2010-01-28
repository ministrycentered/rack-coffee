require 'coffee-script'
require 'rack/file'
require 'rack/utils'

class Rack::Coffee

  attr_accessor :url, :root

  DEFAULTS = {:static => true}

  def initialize(app, opts = {})
    opts = DEFAULTS.merge(opts)
    @app = app
    @url = opts[:url] || '/javascripts'
    @root = opts[:root] || Dir.pwd
    @server = opts[:static] ? Rack::File.new(root) : app
  end

  def call(env)
    path = Rack::Utils.unescape(env["PATH_INFO"])
    return [403, {"Content-Type" => "text/plain"}, ["Forbidden\n"]] if path.include?('..')
    return @app.call(env) unless path.index(url) == 0 && path =~ /\.js$/
    coffee = File.join(root, path.sub(/\.js$/, '.coffee'))
    if File.file?(coffee)
      headers = {
        'Content-Type' => 'application/javascript',
        'Last-Modified' => File.mtime(coffee).httpdate}
      [200, headers, [CoffeeScript.compile(File.read(coffee))]]
    else
      @server.call(env)
    end
  end

end
