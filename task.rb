require 'rest-client'
require 'json'
require 'gruff'
require 'uri'
require 'addressable/uri'
require 'mongo'
require 'open-uri'
require 'rss'
require 'twitter'
require 'nokogiri'

'''
GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVDatosPersonales?param=132827-0-22-108

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVExpeLaboral?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduBasica?Ids=132827-0

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVNoUniversitaria?Ids=132827-0

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduTecnico?Ids=132827-0

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduUniversitaria?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVPosgrado?Ids=132827-0

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVCargoEleccion?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVCargoPartidario?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetHVRenunciaOP?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVSentenciaPenal?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVSentenciaObliga?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVIngresos?Ids=132827-0

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVBienInmueble?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVBienMueble?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVMuebleOtro?Ids=132827-0-ASC

GET https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVInfoAdicional?Ids=132827-0
'''

Mongo::Logger.logger = Logger.new('mongo.log')

headers = {
		"content-type":"application/json", 'User-Agent':"Mozilla/5.0 (Linux; Android 5.0; SM-G920A) AppleWebKit (KHTML, like Gecko) Chrome Mobile Safari (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)"}

$base = "108"
$client = Mongo::Client.new([ 'katari_mongo:27017' ], :database => 'remote')

def pushDatosPersonales(hash)
	construct_id = hash[:idHojaVida].to_s + '-0-' + hash[:idOrganizacionPolitica].to_s + '-' + $base
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVDatosPersonales?param='+construct_id+''.force_encoding('ASCII-8BIT')
	print(construct_id)
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	if data_render['data'].length() > 0
		item = data_render['data'][0]

		if item
			for_set = {}
			item.each do |key, value|
				for_set["listaCandidato.$." + key] = value
			end
			$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
							update_one({"$set"=> for_set })
		end
	end
end

def pushExpLaboral(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	print(hash[:id])
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVExpeLaboral?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.expLaboral" => items} })
end

def pushEduBasica(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduBasica?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.eduBasica" => items} })
end

def pushNoUniv(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVNoUniversitaria?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.noUniversitaria" => items} })
end

def pushEduTecnico(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduTecnico?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.eduTecnico" => items} })
end

def pushEduUniversitaria(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVEduUniversitaria?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.eduUniversitaria" => items} })
end

def pushPosgrado(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVPosgrado?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.eduPosgrado" => items} })
end

def pushCargoEleccion(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVCargoEleccion?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.cargoEleccion" => items} })
end


def pushCargoPartidario(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVCargoPartidario?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.GetAllHVCargoPartidario" => items} })
end

def pushRenuncia(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetHVRenunciaOP?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.renunciaOP" => items} })
end

def pushSentenciaPenal(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVSentenciaPenal?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.sentenciaPenal" => items} })
end

def pushSentenciaOblig(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVSentenciaObliga?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.sentenciaOblig" => items} })
end

def pushIngresos(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVIngresos?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.ingresos" => items} })
end

def pushBienInmueble(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVBienInmueble?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.bienInmueble" => items} })
end

def pushBienMueble(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVBienMueble?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.bienMueble" => items} })
end

def pushMuebleOtro(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVMuebleOtro?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.muebleOtro" => items} })
end


#y demas


print "\n\nSTARTING APP\n"
print "-------------------\n\n"

if ARGV[0] == "partidos"

	url = 'https://plataformaelectoral.jne.gob.pe/Candidato/GetExpedientesLista/108-2-------0-'.force_encoding('ASCII-8BIT')

	response = RestClient::Request.execute(:method => :get, :url => url, :timeout => 100, :open_timeout => 100, :headers=>headers)
	data_render = JSON.parse(response.body)

	$client[:jne].insert_many(data_render['data'])

end


if ARGV[0] == "candidatos"
	print "\n\nGet Candidatos\n\n"
	i=0
	$client[:jne].find().each do |document|

		construct_id = document['idTipoEleccion'].to_s + '-' + $base.to_s + '-' + document['idSolicitudLista'].to_s + '-' +  document['idExpediente'].to_s  
		url = 'https://plataformaelectoral.jne.gob.pe/Candidato/GetCandidatos/'+(construct_id.to_s)+''.force_encoding('ASCII-8BIT')

		response = RestClient.get(url, 
		headers=headers)
		data_render = JSON.parse(response.body)

		$client[:jne].find({"_id" => document['_id']}).update_one({ '$set'=>{ :listaCandidato =>  data_render['data'] } } )
		i+=1
		print "\nGETTING "+i.to_s+"  \n"
		sleep(1.4)
	end
end


if ARGV[0] == "cvs"
	active = false
	$client[:jne].find({'listaCandidato.expLaboral'=>{"$exists"=>false}}).each do |document|
		print "\n\n--\n"
		document['listaCandidato'].each do |candidato|

			idHV = candidato['idHojaVida']

			if idHV.to_s == '130517'
				print 'sssssssssss'
				active = true
			end
			if active == false
				next
			end
			idOrg = document['idOrganizacionPolitica']
			idCandidato = candidato['idCandidato']
			print candidato['idHojaVida']
			print "\n"
			print 'Datos...'
			print "\n"

			pushDatosPersonales({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV, idOrganizacionPolitica:idOrg})
			print 'Exp Laboral..'
			print "\n"
			
			pushExpLaboral({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})

			print 'Edu Basic..'
			print "\n"
			
			pushEduBasica({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'No Univ..'
			print "\n"
			pushNoUniv({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Edu Tecnico..'
			print "\n"
			
			pushEduTecnico({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Edu Univ..'
			print "\n"

			pushEduUniversitaria({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Edu Posgrado..'
			print "\n"
			pushPosgrado({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})

			
			print 'Cargos..'
			print "\n"
			

			pushCargoEleccion({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			pushCargoPartidario({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Renuncia..'
			print "\n"

			pushRenuncia({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Sentencia..'
			print "\n"
			pushSentenciaPenal({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			pushSentenciaOblig({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})

			print 'Ingresos..'
			print "\n"
			pushIngresos({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			print 'Bienes..'
			print "\n"
			pushBienInmueble({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			pushBienMueble({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			pushMuebleOtro({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			print "---------\n\n"
			sleep(1)
		end
		print "\n\n--\n"
	
	end
	#logica
end


if ARGV[0] == 'images'
	$client[:jne].find({}).each do |document| 
		document['listaCandidato'].each do |candidato| 
		   if(File.exist?( './assets/images/' + candidato['idHojaVida'].to_s+".jpg" )) 
		   	puts "existe " +candidato['idHojaVida'].to_s
		   else
			   	puts "descargando" +candidato['idHojaVida'].to_s
			   	begin
					open("https://declara.jne.gob.pe/Assets/Fotos-HojaVida/"+ (candidato['idHojaVida'].to_s) +".jpg") do |image|
					  File.open("./assets/images/"+(candidato['idHojaVida'].to_s)+".jpg", "wb") do |file|
					    file.write(image.read)
					  end
					  sleep(1)
					end
			    rescue OpenURI::HTTPError => ex
				   	puts "no existe" +candidato['idHojaVida'].to_s
			    end
			end
		end
	end
end


if ARGV[0] == 'news'

	agr = [{"$group" => {:_id => "$idOrganizacionPolitica", :orgPolitica => { "$max" => "$strOrganizacionPolitica" } }}];
	$client[:jne].find().each do |document| 
		document['listaCandidato'].each do |candidato|
			
			str = URI::encode('"'+candidato['strCandidato']+'"')
			url = 'https://news.google.com/rss/search?q='+str+'&hl=es-419&gl=PE&ceid=PE:es-419'
			open(url) do |rss|
				feed = RSS::Parser.parse(rss)
				puts "Title: #{feed.channel.title}"
				total_news = []
				feed.items.each do |item|

				  puts "Item: #{item.title}"
				  puts "date: #{item.pubDate}"
				  puts "link: #{item.link}"
				  puts "description: #{item.description}"
				  puts "source: #{item.source}"
				  puts "\n\n"
				  parse_news = {}
				  parse_news[:title] = item.title.to_s
				  parse_news[:link] = item.link.to_s
				  parse_news[:description] = item.description.to_s
				  parse_news[:source] = item.source.to_s
				  parse_news[:date] = item.pubDate.to_s

				  total_news << parse_news
				end

				candidato_bs = $client[:news].find({"idCandidato"=>candidato["idCandidato"]})
				if  candidato_bs.count > 0
					candidato_bs.update_one({"$set"=> {"last_news" => total_news} })
				else
					$client[:news].insert_one({ "nombres"=>candidato["strCandidato"], 
						"idCandidato"=>candidato["idCandidato"],"last_news" => total_news })
				end
			end

		end
	sleep(5)
	end
end

if ARGV[0] == 'last_news'
	$client[:last_news].drop()
	str = URI::encode('"Elecciones 2020"')
	url = 'https://news.google.com/rss/search?q='+str+'&hl=es-419&gl=PE&ceid=PE:es-419'
	open(url) do |rss|
		feed = RSS::Parser.parse(rss)
		puts "Title: #{feed.channel.title}"
		total_news = []
		feed.items.each do |item|

		  puts "Item: #{item.title}"
		  puts "date: #{item.pubDate}"
		  puts "link: #{item.link}"
		  puts "description: #{item.description}"
		  puts "source: #{item.source}"
		  puts "\n\n"
		  parse_news = {}
		  parse_news[:title] = item.title.to_s
		  parse_news[:link] = item.link.to_s
		  parse_news[:description] = item.description.to_s
		  parse_news[:source] = item.source.to_s
		  parse_news[:date] = item.pubDate.to_s
		  html = Nokogiri::HTML.parse(open(item.link.to_s))
		  meta = {}

		  if html.at("meta[property='og\:title']")
			  meta['title'] = html.at("meta[property='og:title']")['content']
		  end
		  if html.at("meta[property='og\:description']")
		  	meta['description'] = html.at("meta[property='og:description']")['content']
		  end

		  if html.at("meta[property='og\:url']")
			  meta['url'] = html.at("meta[property='og:url']")['content']
		  end
		  if html.at("meta[property='og\:image']")
		  	meta['image'] = html.at("meta[property='og:image']")['content']
	 	  end
		  parse_news[:meta] = meta
		  print("inserting...\n")
	      $client[:last_news].insert_one(parse_news)
		end
	end

end

if ARGV[0] == 'twitter'
	client = Twitter::REST::Client.new do |config|
	  config.consumer_key        = "vN7rzm4jRIHDoeJshnlqtZmS1"
	  config.consumer_secret     = "VuTvRgclNZjU5TTcy5EhMgJpaniF1d8AyBa7ULwv4v2dr3sUpt"
	  config.access_token        = "3289401305-MEKgybgm249bSogB2N8psWBQEyHNYdQToxYRKwU"
	  config.access_token_secret = "UnD30V0RqVq72phHunSTg9O6TW9iE43tSqVesDaotQO0X"
	end

	users = [ {"from"=>"ConocelosPeru", "tag"=>""}, {"from"=>"JNE_Peru", "tag"=>"#ECE2020"}, 
			{"from"=>"ONPE_oficial", "tag"=>"#EleccionesCongresales2020"}]
	hashtags = ["#elecciones2020 peru", "#EleccionesCongresales2020", "#ECE2020"]

	$client[:last_tweets].drop()

	hashtags.each do |hs|
		client.search( hs , tweet_mode: "extended", result_type: "mixed").take(20).collect do |tweet|
			if not tweet.retweeted_status?
				$client[:last_tweets].insert_one({ "type"=>"by_search", "keyword"=>hs, :tweet=> tweet.attrs})
			end
		end
	end

	
	users.each do |user|
		client.search("(from:#{user['from']}) "+user['tag'], tweet_mode: "extended", result_type: "recent").take(10).collect do |tweet|
			$client[:last_tweets].insert_one({"type"=>"by_user","keyword"=>user, :tweet=> tweet.attrs})
		end
	end
	
end
