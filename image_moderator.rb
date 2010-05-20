# This app relies on the ProcessImage class in /builder/lib/image_moderator.rb.

require "rubygems"
require "bundler"
Bundler.setup

require 'sinatra'
require 'httparty'
require 'digest/md5'
require 'redis'
require 'json'
require 'resque'
require 'helper_methods'

include HelperMethods

$redis = Redis.new
Resque.redis = $redis

get '/api/imgs' do
  
  content_type :json
  
  url = params[:url]
  key = params[:token]
  client_id = Digest::MD5.hexdigest(key)
  job_id = $redis.get(client_id)
  unit_id = $redis.get("image_moderator:jobs:#{job_id}:url:#{url}")
  
  if not authenticated?(key)
    
    response = { :error => "Not authenticated" }
    
  else
    
    unit_data = HTTParty.get("https://api.crowdflower.com/v1/jobs/#{job_id}/units/#{unit_id}.json?key=#{key}")
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
    response = { :rating => rating, :id => id, :url => url, :created_at => created_at }
    
  end
  
  response.to_json
  
end

post '/api/imgs' do
  
  content_type :json
  
  key = params[:token]
  url = params[:url]
  
  if not authenticated?(key)
    
    # we could make authentication faster by caching the result
    # and expiring after a day, or by caching and refreshing
    # the result in the background every time a call is made.
    # right now this step adds about 600ms to the request loop
    # on my local box.
    
    response = { :error => "Not authenticated"}
    
  # make sure the image URL works using a HEAD request.
  # give up after 10 seconds.
  # it sucks to include this in the request loop, but it's important
  # to notify the user if there's a problem with their URL
  # TODO: what if their image doesn't handle HEAD requests properly?
  elsif HTTParty.head(url, :timeout => 10).code != 200
    
    response = { :url => url, :error => "The image URL did not return a 200 response" }
    
  else
    
    Resque.enqueue(ProcessImage, url, key)
    response = { :success => "Image queued for processing" }
    
  end
  
  response.to_json
  
end