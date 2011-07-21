get '/playlist/refresh' do
  @r = Redis.new
#  Find.find(settings.music_directory) { |f| files << f if f =~ /(mp3$|m4a$|m4p$)/ }
  files = []
  Find.find(settings.music_directory) { |f| files << f if f =~ /(mp3$|m4a$|m4p$)/ }
  regexp = /.*\/(.+)\/(.+)\/(.+)\.([\d\w]+)/
  files = files.map do |r| 
    match = r.match regexp;
    song_title = match[3].sub(/^[\d\- ]+ /, '').downcase
    "#{song_title} [#{match[1]}] #{match[2]}"
  end
  
  # Create the music_file_names sorted set
  @r.del :music_file_names
  
  files.each do |n|
      n.strip!
      (1..(n.length)).each{|l|
          prefix = n[0...l]
          @r.zadd(:music_file_names,0,prefix)
      }
      @r.zadd(:music_file_names,0,n+"*")
  end
  
  if(session['message'])
    session['message'] += " Refreshed."
  else
    session['message'] = "Refreshed the autocompleter."
  end
  
  redirect '/'
end

get '/playlist/add' do
  @r = Redis.new
  
  submitted_fields = params
  submitted_fields.delete('submit')
  submitted_fields.delete('new')
  song_name = submitted_fields.delete('key')

  if(submitted_fields['playlist_name']) 
    new_playlist_name = submitted_fields.delete('playlist_name')
    @r.zadd('playlist_names',0,new_playlist_name)
    @r.zadd("playlist.#{new_playlist_name}",0,song_name)
  end

  submitted_fields.each do |key, value|
    @r.zadd("playlist.#{key}",0,song_name)
  end  

  session['message'] = "Song added to playlist"
  
  redirect '/'
end

get '/playlist/list' do 
  @r = Redis.new
  @results = []

  search_term = params[:term]

  return if search_term.nil?

  search_term.downcase!

  search(@r, search_term, 50, :music_file_names).each{|res|
      @results << res
  }
  @results = ["No Results"] if @results.empty?

  content_type :json
  @results.to_json
end

get '/playlist/show' do
  @r = Redis.new
  @playlists = {}
  @r.zrange('playlist_names', 0, -1).each do |playlist|
    @playlists[playlist] = []
    @r.zrange("playlist.#{playlist}",0,-1).each do |song|
      @playlists[playlist] << song
    end
  end
  
  erb :'playlist/show'
end

get '/playlist/export' do
  @r = Redis.new
  playlists = {}
  @r.zrange('playlist_names', 0, -1).each do |playlist|
    playlists[playlist] = []
    @r.zrange("playlist.#{playlist}",0,-1).each do |song|
      playlists[playlist] << song
    end
  end
  
  log_file = File.open('log/log_' + Time.now.strftime('%Y_%m_%d_%H_%M_%S') + '.txt', 'w')
  
  playlists.each do |playlist_name, songs|
    
    playlist_file = File.open(settings.playlist_directory + playlist_name + ".m3u", 'w')
    
    # Find song in music directory with song information. Let's grab song, artist, and album.
    songs.each do |song_string|
      matches = song_string.match(/^(.*)\[(.*)\](.*)$/)
      if(matches)
        song, artist, album = matches[1].strip, matches[2], matches[3].strip
        bad_regexp_chars = /([\[\]\(\)\{\}\+\=\-])/
        song.gsub!(bad_regexp_chars, '.')
        artist.gsub!(bad_regexp_chars, '.')
        album.gsub!(bad_regexp_chars, '.')
        file_path = %r|#{artist}\/#{album}\/[\d\- ]+#{song}|
        files = []
        
        # search for the matching file
        Find.find(settings.music_directory) { |f| files << f if f =~ file_path }
        
        if(files.length < 1)
          log_file.puts "Song: #{song}\nArtist: #{artist}\nAlbum: #{album}"
          log_file.puts "Total file path: #{file_path}"
          log_file.puts
        elsif(files.length == 1)
          log_file.puts "Found match for #{song_string} at #{files.first}"
          log_file.puts
          playlist_file.puts files.first
        else
          log_file.puts "Found too many matching songs! at #{song_string} with #{files.inspect}"
          log_file.puts
        end
      end
    end
    
    playlist_file.close
  end
  log_file.close
  
  session['message'] = "Export completed."
  redirect '/'
end
