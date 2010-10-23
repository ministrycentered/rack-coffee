require 'test/unit'
begin
  require 'rack/mock'
  require 'rack/lint'
rescue LoadError
  require 'rubygems'
  retry
end

require File.dirname(__FILE__) + "/../lib/rack/coffee"

class DummyApp
  def call(env)  
    [200, {"Content-Type" => "text/plain"}, ["Hello World"]]
  end
end

class RackCoffeeTest < Test::Unit::TestCase
  
  def setup
    @root = File.expand_path(File.dirname(__FILE__))
    @options = {:root => @root}
  end

  def teardown
    File.delete "#{@root}/javascripts/test.js" if File.exists?("#{@root}/javascripts/test.js")
    File.delete "#{@root}/other_javascripts/test.js" if File.exists?("#{@root}/other_javascripts/test.js")
  end
  
  def request(options={})
    options = @options.merge(options)
    Rack::MockRequest.new(Rack::Lint.new(Rack::Coffee.new(DummyApp.new, options)))
  end
  
  def test_serves_coffeescripts
    result = request.get("/javascripts/test.js")
    assert_equal 200, result.status
    assert_match /alert\(\"coffee\"\)\;/, result.body
    # assert_equal File.mtime("#{@root}/javascripts/test.coffee").httpdate, result["Last-Modified"]
    assert_equal File.mtime("#{@root}/javascripts/test.js").httpdate, result["Last-Modified"]
  end
  
  def test_serves_javascripts
    result = request.get("/javascripts/static.js")
    assert_equal 200, result.status
    assert_equal %|alert("static");|, result.body
  end
  
  def test_writes_javascript_to_file
    #create file
    result = request.get("/javascripts/test.js")
    assert File.exists?("#{@root}/javascripts/test.js")
    
    #don't update file
    date = File.mtime("#{@root}/javascripts/test.js")
    result = request.get("/javascripts/test.js")
    assert_equal date, File.mtime("#{@root}/javascripts/test.js")
  
    sleep(1)
    #update file
    File.utime Time.now, Time.now, "#{@root}/javascripts/test.coffee"
    result = request.get("/javascripts/test.js")
    assert_not_equal date, File.mtime("#{@root}/javascripts/test.js")
  end
  
  def test_calls_app_on_path_miss
     result = request.get("/hello")
     assert_equal 200, result.status
     assert_equal "Hello World", result.body
   end
   
   def test_does_not_allow_directory_traversal
     result = request.get("/../README")
     assert_equal 403, result.status
   end
   
   def test_does_not_allow_directory_travesal_with_encoded_periods
     result = request.get("/%2E%2E/README")
     assert_equal 403, result.status
   end
   
   def test_serves_coffeescripts_with_alternate_options
     result = request({:root => File.expand_path(File.dirname(__FILE__)), :urls => "/other_javascripts"}).get("/other_javascripts/test.js")
     assert_equal 200, result.status
     assert_match /alert\(\"other coffee\"\)\;/, result.body
   end
   
   def test_no_wrap_option
     result = request({:nowrap => true}).get("/javascripts/test.js")
     assert_equal "alert(\"coffee\");", result.body
   end
  
end