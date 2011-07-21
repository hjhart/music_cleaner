require 'sinatra'
require 'redis'
require 'json'
require 'find'

enable :sessions

config = JSON.parse(File.open('config.json').read)

configure do
  set :music_directory, config['music_directory']
  set :playlist_directory, config['playlist_directory']
  set :deletion_directory, config['deletion_directory']
end
  
get '/' do
  @r = Redis.new
  @message = session['message']
  session['message'] = nil
  @playlists = @r.zrange(:playlist_names,0,-1)
  erb :index
end

require File.expand_path(File.dirname(__FILE__), 'folder')
require File.expand_path(File.dirname(__FILE__), 'playlist')
require File.expand_path(File.dirname(__FILE__), 'application')