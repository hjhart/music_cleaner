Directory Cleaner
=============

This Sinatra app makes it easy to clean up a directory. It automatically indexes your directory to make autocomplete-enabled input field. Currently it doesn't actually delete directories. It just moves them to another folder.

### Usage

Start up your sinatra app 

Install the prerequisites (redis, json, sinatra)

	gem install redis
	gem install json
	gem install sinatra
	
### Configure your server.

Go into main.rb and set the below direcotries to what you want

	configure do
	  set :music_directory, '/Users/jhart/Music/iTunes/iTunes Media/Music/'
	  set :deletion_directory, '/Users/jhart/Music/Deleted Music/'
	end

This will parse through your `music_directory` and move all 'deleted' directories to the `deletion_directory`

Start your server

	ruby -rubygems main.rb
	
Rebuild the index by pointing your browser to localhost:4567/refresh

Now add a direcotry to the deletion queue by typing in a search term. The autocompleter will bring up all of your directories automatically and make it easy for you to select one. Select a directory and press the delete button.

After you've done this a few times you can click "Show queue." This will be the page where it lists the directories you've chosen and you can confirm the delete.

### Logs

Logs are put into the log/ directory


### How to help.

This is supposed to be good for a mobile browser, but right now I'm loading up jQuery and jQuery UI. That's about 120 kb of junk just for an autocompleter. Let's reduce that size? Also: The UI Sucks. Help with that.