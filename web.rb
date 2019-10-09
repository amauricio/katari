require 'sinatra'
require 'json'
require 'redis'
require 'rest-client'
require 'gruff'

def generate_sentiment_graph(hash)
	g = Gruff::Line.new("120x50")
	g.font = '/app/fonts/arial.ttf' # Path to a custom font

	g.data :response, hash[:points]
	g.hide_legend = true
	g.hide_line_markers = true
	g.theme = {   # Declare a custom theme
	  :background_colors => %w(white white) # you can use instead: :background_image => ‘some_image.png’
	}
	g.write('assets/graphs/'+hash[:name]+'.png')
end
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/assets'

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
		url = 'http://copperni.co/api/v1/news?q="'+ d['name'] +'"'
		response = RestClient.get(url, 

		headers={
			"Accept":"application/json",
			"content-type":"application/json",
			'x-api-key':'Boctrg4ao_hkry9cvS8T1s4Q8hwPNquxA7m_ShwFN7c'})
		r = JSON.parse(response.body)['response']
		data.push(r)
		$Redis.set('news_'+item , r)
	end
	json data
end
get '/request_persons' do
	persons = [{
			"id":"100190",
			"name":"Pedro Olaechea",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Pedro_Olaechea_AC.jpg/220px-Pedro_Olaechea_AC.jpg"},
			{
			"id":"100180",
			"name":"Martin Vizcarra",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Mart%C3%ADn_Vizcarra_Cornejo_%28cropped%29_%28cropped%29.png/800px-Mart%C3%ADn_Vizcarra_Cornejo_%28cropped%29_%28cropped%29.png"},
		{
			"id":"100170",
			"name":"Keiko Fujimori", 
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Keiko_Fujimori_2.jpg/220px-Keiko_Fujimori_2.jpg"}, 
		{
			"id":"100120",
			"name":"Cesar Acuna",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/6/6b/C%C3%A9sar_Acu%C3%B1a_Peralta_-_CAP.jpg"},
		{
			"id":"100110",
			"name":"Pedro Pablo kuczynski",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/Pedro_Pablo_Kuczynski_2016_%28cropped%29.jpg/230px-Pedro_Pablo_Kuczynski_2016_%28cropped%29.jpg"}, 
		{
			"id":"100220",
			"name":"Luis Castaneda",
			"photo":"https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Lcl.JPG/1200px-Lcl.JPG"}]
	result = []
	for pe in persons do
		url = 'http://copperni.co/api/v1/sentiment?q="'+ pe[:name] +'"&time=daily'
		response = RestClient.get(url, 
		headers={
			"content-type":"application/json",
			'x-api-key':'Boctrg4ao_hkry9cvS8T1s4Q8hwPNquxA7m_ShwFN7c'})

		data_render = JSON.parse(response.body)['response']
		nmb_data = []
		negative = 0
		positive = 0
		data_render['summary'].each do |s|
			if s['polarity'] == 'positive'
				positive = s['total']
			end
			if s['polarity'] == 'negative'
				negative = (s['total'] + ((1-s['total'])*0.2) )*-1
			end
		end

		new_range_min = 0
		new_range_max = 100
		negative = (((negative - (-1)) * (new_range_max - new_range_min)) / (1 - (-1))) + 0
		positive = (((positive - (-1)) * (new_range_max - new_range_min)) / (1 - (-1))) + 0

		score = negative  + (positive*0.2)

		data_render['history'].each do |h|
			total = h['total']**2
			if h['polarity'] == 'negative'
				total = h['total'] * -0.05
			end
			nmb_data.push(total)
		end
		generate_sentiment_graph({"name": pe[:name], "points":nmb_data})
		to_data = {
			"id": pe[:id],
			"photo": pe[:photo], 
			"score": 100 - (score).round(0),
			"graph": 'graphs/'+pe[:name]+'.png',
			"name": pe[:name],
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

	return @news.force_encoding("ISO-8859-1")
end
get '/persons' do
	result = JSON.parse($Redis.get("persons"))
	
	erb :grid_persons, :locals => {:result=>result}
end

get '/' do
	

	#count = $Redis.incr( "request_count" )
	#json :count => count
	erb :index,:layout => :app,  :locals => {"por"=>response.body}
end