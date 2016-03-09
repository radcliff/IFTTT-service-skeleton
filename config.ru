$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'dotenv'
Dotenv.load

require 'bundler'
Bundler.require

require 'find'

%w{config lib}.each do |load_path|
  Find.find(load_path) { |f|
    require f unless f.match(/\/\..+$/) || File.directory?(f)
  }
end

require 'service'
run Service
