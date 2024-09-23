# frozen_string_literal: true
require 'bundler/setup'
require 'sinatra'

set :port, 80

get '/up' do
  "OK"
end

get '/' do
  "Hello from pack!"
end
