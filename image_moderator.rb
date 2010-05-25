# This app depends on the ProcessImage class in /builder/lib/image_moderator.rb.

require "rubygems"
require "bundler"
Bundler.setup

require 'sinatra'
require 'httparty'
require 'digest/md5'
require 'redis'
require 'json'
require 'resque'

configure :development do
  set :base_uri, "http://api.localhost.com:4000/"
end

configure :production do
  set :base_uri, "https://api.crowdflower.com/"
end

$redis = Redis.new
Resque.redis = $redis

get '/api/imgs/:id' do
  
  content_type :json
  
  url = params[:url]
  filename = Digest::MD5.hexdigest(url)
  key = params[:token]
  job_id = $redis.get("image_moderator:#{key}")
  unit_id = $redis.get("image_moderator:jobs:#{job_id}:filename:#{filename}")
    
  unit_data = get_unit_data(job_id, unit_id, key)
  response = format_response(unit_data, url)
    
  response.to_json
  
end

post '/api/imgs/:id' do
  
  content_type :json
  
  key = params[:token]
  url = params[:url]
    
  if authenticated?(key)
    
    Resque.enqueue(ProcessImage, url, key)
    response = { :success => "Image queued for processing. If an error is "  \
                             "encountered, a notification will be posted "   \
                             "to your webhook URI (if applicable)." }
  else
    
    response = { :error => "Authentication unsuccessful" }
    throw :halt, [401, response.to_json]
    
  end
  
  response.to_json
  
end

post '/forward_webhook' do
  
  content_type :json
  
  client_webhook_uri = params[:webhook_uri]
  puts client_webhook_uri
  
  if params[:signal] == 'unit_complete'
  
    unit_data = params[:payload]
    puts unit_data.inspect
    response = format_response(unit_data, unit_data['data']['url'])
    
    HTTParty.post(client_webhook_uri, :body => response)
    
  elsif params[:test]
    
    sample_data = {
      :rating => 0,
      :id => 2,
      :url => "http://acme.crowdsifter.com/imgs/good.jpg",
      :created_at => "2008-09-26T18:21:49Z"
    }
    HTTParty.post(client_webhook_uri, :body => sample_data)
    
  elsif params[:error]
    
    HTTParty.post(client_webhook_uri, :body => error)
    
  end
  
  
end


#############################################################################



# this is here so that Resque knows how to queue the job
class ProcessImage
  
  @queue = :low
  
end

def authenticated?(key)
  
  HTTParty.get(options.base_uri + "v1/account.json?key=#{key}").code == 200
  
end

def get_unit_data(job_id, unit_id, key)
  
  unit_data = HTTParty.get(
    options.base_uri + "v1/jobs/#{job_id}/units/#{unit_id}.json?key=#{key}"
    )
  throw :halt, [401, "Not authenticated"] if unit_data.code == 401
  throw :halt, [404, "Not found"] if unit_data.code == 404
  unit_data
  
end

def format_response(unit_data, url)
  
  agg = unit_data['results']['is_porn']['agg']
  confidence = unit_data['results']['is_porn']['confidence']
  
  # use confidence as the rating if agg is true. if agg is false,
  # the rating should be the inverse of confidence.
  # (rating should be a value between 0 and 1, where 0 is definitely
  # not porn and 1 is definitely porn)
  if confidence
    rating = agg == true ? confidence : 1 - confidence
  else
    rating = nil
  end
  
  id = unit_data['id']
  created_at = unit_data['created_at']
  response = {  
    :rating => rating, 
    :id => id, 
    :url => url, 
    :created_at => created_at 
    }
  
end