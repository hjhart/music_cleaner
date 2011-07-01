require 'sinatra'
require 'redis'
require 'json'

enable :sessions

configure do
  set :music_directory, '/Volumes/Media/Music/'
  set :deletion_directory, '/Volumes/Media/Deleted Music/'
end

get '/' do
  @message = session['message']
  session['message'] = nil
  erb :index
end

get '/list' do 
  @r = Redis.new
  @results = []
  
  search(@r,params[:term],50).each{|res|
      @results << res
  }
  
  content_type :json
  @results.to_json
end

get '/delete' do
  @r = Redis.new
  if(params[:delete])
    @r.zadd(:folders_to_delete,0,params[:key])
    session['message'] = "Popped '#{params[:key]}' into the deletion queue."
  else
    @r.zadd(:folders_to_refactor,0,params[:key])
    session['message'] = "Popped '#{params[:key]}' into the problem queue."
  end

  redirect '/'
end

get '/confirm' do
  @r = Redis.new
  @records = @r.zrange(:folders_to_delete,0,-1)
  @result = []
  @records.each do |rec|
    if File.directory?(settings.music_directory + rec)
      File.rename(settings.music_directory + rec, settings.deletion_directory + rec)
      @result << "Moved #{settings.music_directory}#{rec} to #{settings.deletion_directory}#{rec}"
    else
      @result << "#{settings.music_directory} was not a directory. Did not delete."
    end
  end
  
  file = File.open('log/log_' + Time.now.strftime('%Y_%m_%d_%H_%M_%S') + '.txt', 'w')
  @result.each do |res|
    file.puts res
  end
  
  @r.del :folders_to_delete
  @r.del :folders_to_refactor
  
  session['message'] = "Deleted folders."
  redirect '/refresh'
end

get '/show' do
  @r = Redis.new
  @delete_records = @r.zrange(:folders_to_delete,0,-1)
  @problem_records = @r.zrange(:folders_to_refactor,0,-1)
  erb :show
end
        
get '/refresh' do
  @r = Redis.new
  directories = Dir[settings.music_directory + "/" + '**'].select { |f| File::directory?(f) }.map { |f| f.match(/.*\/(.*)$/)[1] }
  
  # Create the artist_folders sorted set
  @r.del :artist_folders
  
  directories.each do |n|
      n.strip!
      (1..(n.length)).each{|l|
          prefix = n[0...l]
          @r.zadd(:artist_folders,0,prefix)
      }
      @r.zadd(:artist_folders,0,n+"*")
  end
  
  if(session['message'])
    session['message'] += " Refreshed."
  else
    session['message'] = "Refreshed the autocompleter."
  end
  
  redirect '/'
end

def search(r,prefix,count)
    results = []
    rangelen = 50 # This is not random, try to get replies < MTU size
    start = r.zrank(:artist_folders,prefix)
    return [] if !start
    while results.length != count
        range = r.zrange(:artist_folders,start,start+rangelen-1)
        start += rangelen
        break if !range or range.length == 0
        range.each {|entry|
            minlen = [entry.length,prefix.length].min
            if entry[0...minlen] != prefix[0...minlen]
                count = results.count
                break
            end
            if entry[-1..-1] == "*" and results.length != count
                results << entry[0...-1]
            end
        }
    end
    return results
end
