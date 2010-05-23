require 'rubygems'
require 'image_moderator'
require 'test/unit'
require 'rack/test'

API_KEY = '71530356758fab72bb60645750e08d16af01fa19'
TEST_IMAGE = "http://localhost:4000/images/marketing/crowdflower_logo.png"

set :environment, :test

class ImageModeratorTest < Test::Unit::TestCase
  
  include Rack::Test::Methods
  
  def app
    
    Sinatra::Application
    
  end
  
  def assert_contains(string, *regexes)
    
    regexes.each {|regex| assert last_response.body =~ /#{regex}/ }
    
  end
  
  def test_it_returns_a_401
    
    post '/api/imgs', :url => "http://www.obvi.com/puppies.jpg", :token => '9532k4l329fs09fsjkl43'
    assert last_response.status == 401
    assert last_response.body == '{"error":"Authentication unsuccessful"}'
    
  end
  
  def test_it_accepts_a_post
    
    post '/api/imgs', :url => TEST_IMAGE, :token => API_KEY
    assert last_response.status == 200
    assert last_response.body =~ /Image queued for processing/
    
  end
  
  def test_it_returns_the_result
    
    get '/api/imgs', :url => TEST_IMAGE, :token => API_KEY
    assert last_response.status == 200
    assert last_response.body =~ /rating/ 
    assert_contains last_response.body, "rating", "created_at", "url", "id"
    
  end
  
end