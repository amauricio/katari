#encoding: utf-8

require 'sinatra'
require 'json'
require 'redis'
require 'rest-client'
require 'gruff'
require 'uri'
require 'addressable/uri'
require 'mongo'


client = Mongo::Client.new([ 'katari_mongo:27017' ], :database => 'partidos')

def generate_sentiment_graph(hash)
	g = Gruff::Line.new("320x120")
	g.font = '/app/fonts/arial.ttf' # Path to a custom font

	g.data :response, hash[:points]
	g.hide_legend = true
	g.hide_line_markers = true
	g.theme = {   # Declare a custom theme
	  :background_colors => %w( white white) # you can use instead: :background_image => ‘some_image.png’
	}
	g.write('assets/graphs/'+hash[:id]+'.png')

	g = Gruff::Line.new("320x120")
	g.font = '/app/fonts/arial.ttf' # Path to a custom font

	g.data :response, hash[:points]
	g.hide_legend = true
	g.hide_line_markers = true
	g.theme = {   # Declare a custom theme
	  :background_colors => %w( white white) # you can use instead: :background_image => ‘some_image.png’
	}
	g.write('assets/graphs/'+hash[:id]+'_detail.png')
end
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/assets'
enable :sessions

# configure redis

def json(hash)
  content_type :json
  hash.to_json
end


get '/detail/:id' do
	@person = $Redis.get ("person_" +(params[:id]) )
	@news = $Redis.get('news_' + params[:id])

	erb :detail, :layout => :app,:locals => {:news=>JSON.parse(@news), :person=>JSON.parse(@person)}
end
get '/persons' do
	result= []
	for item in JSON.parse($Redis.get('person_ids')) do
		@person = $Redis.get ("person_" +(item) )
		result.append(JSON.parse(@person))
	end
	erb :grid_persons, :locals => {:result=>result}
end

get '/' do
	

	#count = $Redis.incr( "request_count" )
	#json :count => count
	erb :index,:layout => :app,  :locals => {"por"=>response.body}
end