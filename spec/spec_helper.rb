# encoding: UTF-8

require 'dotenv'
Dotenv.load

require 'bundler'
Bundler.setup
Bundler.require

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'

require 'find'
%w{config lib}.each do |load_path|
  Find.find(load_path) { |f|
    require f unless f.match(/\/\..+$/) || File.directory?(f)
  }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.color = true
  config.formatter = :documentation
end
