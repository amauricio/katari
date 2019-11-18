#encoding: utf-8

require 'sinatra'
require 'json'
require 'redis'
require 'rest-client'
require 'gruff'
require 'uri'
require 'addressable/uri'

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
$Redis = Redis.new(host: "redis", port: ENV["REDIS_PORT_6379_TCP_PORT"])

def json(hash)
  content_type :json
  hash.to_json
end


get '/request_news' do
	
	data =[]
	for item in JSON.parse($Redis.get('person_ids')) do

		@person = $Redis.get ("person_" +(item) )

		d = JSON.parse(@person)
		url = 'http://copperni.co/api/v1/news?q='+ d['name'] +''.force_encoding('ASCII-8BIT')
		print(url + "\n")

		url = URI::encode(url)

		response = RestClient.get(url, 

		headers={
			"Accept":"application/json",
			"content-type":"application/json",
			'x-api-key':'Boctrg4ao_hkry9cvS8T1s4Q8hwPNquxA7m_ShwFN7c'})
		r = response.body
		data.push(r)
		$Redis.set('news_'+item , r)
	end
	return data
end
get '/request_persons' do
	persons = [{
			"id":"100090",
			"name":"Mercedes Aráoz",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Mercedes_Araoz.jpg/1200px-Mercedes_Araoz.jpg"},
			{
			"id":"100190",
			"name":"Pedro Olaechea",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Pedro_Olaechea_AC.jpg/220px-Pedro_Olaechea_AC.jpg"},
			{
			"id":"100180",
			"name":"Martín Vizcarra",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Mart%C3%ADn_Vizcarra_Cornejo_%28cropped%29_%28cropped%29.png/800px-Mart%C3%ADn_Vizcarra_Cornejo_%28cropped%29_%28cropped%29.png"}]
	result = []
	for pe in persons do
		url = 'http://copperni.co/api/v1/sentiment?q='+ pe[:name]+'&time=daily'.force_encoding('ASCII-8BIT')
		url = URI::encode(url)
		response = RestClient.get(url, 
		headers={
			"content-type":"application/json",
			'x-api-key':'Boctrg4ao_hkry9cvS8T1s4Q8hwPNquxA7m_ShwFN7c'})
		print(response)
		data_render = JSON.parse(response.body)['response']
		nmb_data = []
		negative = 0
		positive = 0

		data_render['summary'].each do |s|
			if s['polarity'] == 'positive'
				positive = s['total']	
			end
			if s['polarity'] == 'negative'
				negative = (s['total']) #+ ((1-s['total'])*0.2) )*-1
			end
		end

		score = negative  #+ (positive*0.2)
		
		new_range_min = 0
		new_range_max = 100
		negative = (((negative - (-1)) * (new_range_max - new_range_min)) / (1 - (-1))) + 0
		positive = (((positive - (-1)) * (new_range_max - new_range_min)) / (1 - (-1))) + 0


		data_render['history'].each do |h|
			total = h['total']**2
			if h['polarity'] == 'negative'
				total = h['total'] * -0.05
			end
			nmb_data.push(total)
		end
		nname = pe[:name].encode("UTF-8")

		generate_sentiment_graph({"id": pe[:id], "points":nmb_data})
		to_data = {
			"id": pe[:id],
			"photo": pe[:photo], 
			"score": (data_render['summary']),
			"graph": 'graphs/'+pe[:id]+'.png',
			"name": nname,
			"data": data_render}
		result.append(pe[:id])
		$Redis.set ("person_" + pe[:id]), to_data.to_json

		

	end
	$Redis.set ("person_ids"), result.to_json

	json :message => "saved" 

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