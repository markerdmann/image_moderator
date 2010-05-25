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
    
    regexes.each {|regex| assert string =~ regex }
    
  end
  
  def check_time(string)
    
    # this could fail if i didn't use the right strftime settings or
    # if the time is set a second after the hour changes
    hour = Time.now.gmtime.strftime("%H")
    date = Time.now.gmtime.strftime("%b %d %Y")
    assert_contains(string, /#{hour}:\d{2} #{date}/) 
    
  end
  
  def test_it_returns_a_401
    
    post '/api/imgs/0', :url => "http://www.obvi.com/puppies.jpg", :token => '9532k4l329fs09fsjkl43'
    assert last_response.status == 401
    assert last_response.body == '{"error":"Authentication unsuccessful"}'
    
  end
  
  def test_it_accepts_a_post
    
    # set a job (normally the AM would do this)
    # the job must have the appropriate fields
    $redis.set("image_moderator:#{API_KEY}", 10700)
    post '/api/imgs/0', :url => TEST_IMAGE, :token => API_KEY
    assert last_response.status == 200
    assert last_response.body =~ /Image queued for processing/
    
  end
  
  def test_it_returns_the_result
    
    get '/api/imgs/0', :url => TEST_IMAGE, :token => API_KEY
    assert last_response.status == 200
    assert last_response.body =~ /rating/ 
    assert_contains last_response.body, /rating/, /created_at/, /url/, /id/
    
  end
  
  def test_webhook_sends_test_data
    
    
    post '/forward_webhook?webhook_uri%3Dhttp%3A%2F%2Fwww.postbin.org%2F1jl062e&test%3Dtrue'
    response_body = HTTParty.get("http://www.postbin.org/1jl062e").body
    check_time(response_body)
    assert last_response.status == 200
    
  end
  
  def test_webhook_sends_real_data
    
    payload = {
      "results" =>
        {
          "judgments" => [],
          "is_porn" => {"agg" => nil,"confidence" => 0.5}
        },
        "job_id" => 10700,
        "state" => "new",
        "created_at" => "2010-05-24T17:31:17-07:00",
        "data" => 
          {"url" => "http://localhost:4000/images/marketing/crowdflower_logo.png",
            "thumbnail_url" => "http://s3.amazonaws.com/jday_test/1dce4fe73a108e7c05fc6aceb77881e5.png"
          },
        "difficulty" => 0,
        "updated_at" => "2010-05-24T17:31:17-07:00",
        "judgments_count" => 0,
        "id" => 14239444
    }
    post '/forward_webhook?webhook_uri%3Dhttp%3A%2F%2Fwww.postbin.org%2F1jl062e', :signal => :unit_complete, :payload => payload.to_json
    response_body = HTTParty.get("http://www.postbin.org/1jl062e").body
    check_time(response_body)
    assert last_response.status == 200
    
  end
  
end