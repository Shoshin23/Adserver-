require 'rubygems'
require 'sinatra'

require 'adserver'
set :environment, :production
#optional 
run Sinatra.application
