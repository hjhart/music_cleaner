get '/folder/list' do 
  @r = Redis.new
  @results = []
  
  search(@r,params[:term],50, :artist_folders).each{|res|
      @results << res
  }
  
  content_type :json
  @results.to_json
end

get '/folder/delete' do
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

get '/folder/confirm' do
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
  redirect '/folder/refresh'
end

get '/folder/show' do
  @r = Redis.new
  @delete_records = @r.zrange(:folders_to_delete,0,-1)
  @problem_records = @r.zrange(:folders_to_refactor,0,-1)
  erb :'folder/show'
end
        
get '/folder/refresh' do
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