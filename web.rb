#encoding: utf-8

require 'sinatra'
require 'json'
require 'redis'
require 'rest-client'
require 'uri'
require 'addressable/uri'
require 'mongo'
require 'active_support/inflector'
require 'open-uri'
require 'rss'
require 'nokogiri'

Mongo::Logger.logger = Logger.new('mongo.public.log')
$client = Mongo::Client.new([ 'katari_mongo:27017' ], :database => 'remote')


def disueltos()
	cods = [158919, 160597, 161417, 161192, 160809, 160585, 160806, 158404, 160455, 160564, 
			160569, 161418, 158379, 160496, 157958, 161992,160523, 161193, 160807]
	return cods
end

def totem(d)
	m = {"PARTIDO DEMOCRATICO SOMOS PERU"=> "Somos Peru",
		"PARTIDO APRISTA PERUANO"=> "APRA",
		"PARTIDO POLÍTICO AVANZA PAIS - PARTIDO DE INTEGRACION SOCIAL"=> "Avanza País",
		"AVANZA PAIS - PARTIDO DE INTEGRACION SOCIAL"=> "Avanza País",
		"PARTIDO POLITICO NACIONAL PERU LIBRE"=> "Perú Libre",
		"PARTIDO POLÍTICO EL FRENTE AMPLIO POR JUSTICIA, VIDA Y LIBERTAD"=> "Frente Amplio",
		"EL FRENTE AMPLIO POR JUSTICIA, VIDA Y LIBERTAD"=> "Frente Amplio",
		"PARTIDO POLÍTICO SOLUCION NACIONAL"=> "Solución Nacional",
		"FRENTE POPULAR AGRICOLA FIA DEL PERU - FREPAP"=> "FREPAP"
	}
	if m.key?(d) 
		return m[d]
	end 
	return d
end

def get_host(source)
	html= Nokogiri::HTML.parse(source)
	return html.at("source[url]")['url']
end


set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/assets'
enable :sessions

# configure redis

def json(hash)
  content_type :json
  hash.to_json
end




def base()
	return [
	 { "$sort"=> {"idExpediente"=>1} },
      {"$match"=> { "listaCandidato.expLaboral.idHojaVida"=> {"$exists"=>true} } },
     {"$unwind"=> "$listaCandidato"},
     {"$unwind"=> "$listaCandidato.sentenciaOblig"},
     {"$unwind"=> "$listaCandidato.sentenciaPenal"},

     {"$unwind"=> "$listaCandidato.noUniversitaria"},
     {"$unwind"=> "$listaCandidato.eduTecnico"},
     {"$unwind"=> "$listaCandidato.eduUniversitaria"},

     {"$unwind"=> "$listaCandidato.renunciaOP"},
     {"$unwind"=> "$listaCandidato.expLaboral"},
     {"$unwind"=> "$listaCandidato.GetAllHVCargoPartidario"},


     {"$group"=> {"_id"=>"$listaCandidato.idCandidato", 
     	 "id" => {"$first"=>"$listaCandidato.idCandidato"},
     	 "idHojaVida" => {"$first"=>"$listaCandidato.idHojaVida"},
         "nombres"=>{"$first"=>"$listaCandidato.strCandidato"},
         "logo" => {"$first"=>"$image"}, 
         "region" => {"$first"=> "$strRegion"}, 
         "numero" => {"$first"=>"$listaCandidato.intPosicion"},
         "partido" => {"$first"=> "$strOrganizacionPolitica"},
         "image" => {"$first"=>"$listaCandidato.strRutaArchivo"}, 
         "dni" => {"$first"=>"$listaCandidato.strDocumentoIdentidad"}, 
         "sentenciaOblig" => {"$addToSet"=> "$listaCandidato.sentenciaOblig"  },
         "sentenciaPenal" => {"$addToSet"=> "$listaCandidato.sentenciaPenal"  },

         "expLaboral" => {"$addToSet"=> "$listaCandidato.expLaboral"  },
         "cargoPartidario" => {"$addToSet"=> "$listaCandidato.GetAllHVCargoPartidario"  },

         "noUniversitaria" => {"$addToSet"=> "$listaCandidato.noUniversitaria"  },
         "eduTecnico" => {"$addToSet"=> "$listaCandidato.eduTecnico"  },
         "eduUniversitaria" => {"$addToSet"=> "$listaCandidato.eduUniversitaria"  },
         "eduPosgrado" => {"$addToSet"=> "$listaCandidato.eduPosgrado"  },
         "renunciaOP" => {"$addToSet"=> "$listaCandidato.renunciaOP"  },
         "fecNac" => {"$first" => "$listaCandidato.strFechaNacimiento" }
         }},
         
         {"$project"=> {"_id"=>0, 
         	"idHojaVida"=>1,
         		"image"=>1,"logo"=>1,"region"=>1,"id"=>1, "numero"=>1,"dni"=>1,"age"=>

         		 {"$divide" => [{ "$subtract"=> [ Date.today, { "$dateFromString"=> {
				    "dateString"=> "$fecNac",
				     "format"=> "%d/%m/%Y"
				} }]}, (365 * 24*60*60*1000)  ]},
         		"partido"=>1,
         		"nombres"=> 1,
     		  "sentenciaOblig"=> {
                  "$filter"=> {
                    "input"=> "$sentenciaOblig",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoSentenciaObliga", "1"] }
                        
                  }
              
              },
              "sentenciaPenal"=> {
                  "$filter"=> {
                    "input"=> "$sentenciaPenal",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoSentenciaPenal", "1"] }
                        
                  }
              
              },"noUniversitaria"=> {
                  "$filter"=> {
                    "input"=> "$noUniversitaria",
                    "as"=> "item",
                    "cond"=>  
                            {"$and" => [{"$eq"=> ["$$item.strTengoNoUniversitaria", "1"]}, {"$eq"=> ["$$item.strEduNoUniversitaria", "1"]}] }
                        
                  }
              
              },"eduTecnico"=> {
                  "$filter"=> {
                    "input"=> "$eduTecnico",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoEduTecnico", "1"] }
                        
                  }
              
              },"eduPosgrado"=> {
                  "$filter"=> {
                    "input"=> "$eduPosgrado",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoPosgrado", "1"] }
                        
                  }
              
              },"eduUniversitaria"=> {
                  "$filter"=> {
                    "input"=> "$eduUniversitaria",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoEduUniversitaria", "1"] }
                        
                  }
              
              },"renunciaOP"=> {
                  "$filter"=> {
                    "input"=> "$renunciaOP",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoRenunciaOP", "1"] }
                        
                  }
              
              },"expLaboral"=> {
                  "$filter"=> {
                    "input"=> "$expLaboral",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoExpeLaboral", "1"] }
                        
                  }
              
              },"cargoPartidario"=> {
                  "$filter"=> {
                    "input"=> "$cargoPartidario",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoCargoPartidario", "1"] }
                        
                  }
              
              }}},
             {"$addFields"=> 
             	{ "sentencias" => {"$sum"=> [ {"$size"=>"$sentenciaOblig"}, {"$size"=>"$sentenciaPenal"} ]},
             	"countRenunciaOP" => {"$sum"=> [ {"$size"=>"$renunciaOP"} ]},
             	"countExpLaboral" => {"$sum"=> [ {"$size"=>"$expLaboral"} ]},
             	"countCargoPartidario" => {"$sum"=> [ {"$size"=>"$cargoPartidario"} ]},
             	"edSuperior" => {"$sum"=> [ {"$size"=>"$noUniversitaria"}, {"$size"=>"$eduTecnico"}, {"$size"=>"$eduUniversitaria"} ]}}

             },
	    
	      
    
	   ];
end

def partidos()
	return  [
		
	 { "$sort"=> {"idExpediente"=>1} },

     {"$match"=> { "listaCandidato.expLaboral.idHojaVida"=> {"$exists"=>true} } },
     {"$unwind"=> "$listaCandidato"},
     {"$unwind"=> "$listaCandidato.sentenciaOblig"},
     {"$unwind"=> "$listaCandidato.sentenciaPenal"},
     {"$group"=> {"_id"=>"$idOrganizacionPolitica", 
         
         "candidatos" => {"$addToSet"=>"$listaCandidato" },
         
         "sentenciaOblig" => {"$addToSet"=> "$listaCandidato.sentenciaOblig"  },
         "sentenciaPenal" => {"$addToSet"=> "$listaCandidato.sentenciaPenal"  },
         "orgPolitica"=> {"$max"=>"$strOrganizacionPolitica" },
         "image"=> {"$first"=>"$image"}

         }},
     	
          
          {"$project"=> {"_id"=>1,"orgPolitica"=>1,"image"=>1, "sentenciaOblig"=> {
                  "$filter"=> {
                    "input"=> "$sentenciaOblig",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoSentenciaObliga", "1"] }
                        
                  }
              
              },"sentenciaPenal"=> {
                  "$filter"=> {
                    "input"=> "$sentenciaPenal",
                    "as"=> "item",
                    "cond"=>  
                            {"$eq"=> ["$$item.strTengoSentenciaPenal", "1"] }
                        
                  }
              
              }, "candidatos"=>{"$size"=>"$candidatos"}} }
          
    
	   ];
end

#$client[:jne].indexes.create_one( { "listaCandidato.strCandidato"=> "text" } )

get '/detail/:id' do
	agr = base()
   	agr <<  {"$match" => { "id" =>  params[:id].to_i}}
    agr<< {"$limit"=> 1 }

	person = $client[:jne].aggregate(agr, {allow_disk_use: true}).first

	candidato_bs = $client[:news].find({"idCandidato"=>params[:id].to_i})
	if  candidato_bs.count > 0
		puts "already exist"
		#candidato_bs.find({"$set"=> {"last_news" => total_news} })
	else

		str = URI::encode('"'+person['nombres']+'"')
		url = 'https://news.google.com/rss/search?q='+str+'&hl=es-419&gl=PE&ceid=PE:es-419'
		open(url) do |rss|
			feed = RSS::Parser.parse(rss)
			total_news = []
			feed.items.each do |item|
			  parse_news = {}
			  parse_news[:title] = item.title.to_s
			  parse_news[:link] = item.link.to_s
			  parse_news[:description] = item.description.to_s
			  parse_news[:source] = item.source.to_s
			  parse_news[:date] = item.pubDate.to_s

			  total_news << parse_news
			end
			$client[:news].insert_one({ "nombres"=>person["nombres"], 
				"idCandidato"=>person["id"],"last_news" => total_news })
		end

	end    


	news = $client[:news].find(:idCandidato => params[:id].to_i)
	erb :detail, :layout => :app,:locals => {:active=>'personas',:news=>news, :person=>person}
end


get '/grid-partidos' do
	result= []
	
		agr = partidos()

	   page = 1
	   if (params[:page].to_i) > 0
	   		page = (params[:page].to_i-1)
	   end

	   agr<< { "$skip"=> (page) * 20 }
	   agr<< {"$limit"=> 20 }

	   results = $client[:jne].aggregate(agr, {allow_disk_use: true})

	   if results.count == 0
	   	status 404
	   end
	
	erb :grid_partidos, :locals => {  :result=>results}
end

get '/grid-personas' do
	result= []

	fs_match = []
	search = params[:q]
	if search
	   	fs_match <<  { "$match"=> { "listaCandidato.strCandidato"=> { "$regex"=> /#{search}/i } }}
    end

    region = params[:region]
    if region !=  "1"
	   fs_match <<  { "$match"=> { "strRegion"=> { "$regex"=> /#{region}/i } }}
	end
		agr = base()
	   	agr =  fs_match + agr


	   if search
		   agr <<  { "$match"=> { "nombres"=> { "$regex"=> /#{search}/i } }}
	   end
	   
	   sentencias = params[:sentencias]
	   if sentencias == "1"
	   	agr <<  {"$match" => { "sentencias" => 0}}
	   end

	   estudios = params[:estudios]
	   if estudios == "1"
	   	agr <<  {"$match" => { "edSuperior" =>  { "$gte" => 1 } }}
	   end

	   cargo = params[:cargo]
	   if cargo == "1"
	   	agr <<  {"$match" => { "countCargoPartidario" =>  { "$gte" => 1 } }}
	   end


	   page = 1
	   if (params[:page].to_i) > 0
	   		page = (params[:page].to_i-1)
	   end
	   agr<< { "$sort"=> {"nombres"=>1} }
	   agr<< { "$skip"=> (page) * 20 }
	   agr<< {"$limit"=> 20 }

	   results = $client[:jne].aggregate(agr, {allow_disk_use: true})

	   if results.count == 0
	   	status 404
	   end
	erb :grid_personas, :locals => { :search=>search, :result=>results}
end


get '/img/logo-id' do

	id = params[:id]
	data = $client[:jne].find({'idOrganizacionPolitica'=> id.to_i}).limit(1).first
	if data
		content_type 'image/jpg'
		Base64.decode64(data["image"].split(',')[1])
	else
	   	send_file File.expand_path('index.jpeg', settings.public_folder)
	end
end

get '/' do
	
	erb :personas,:layout => :app,  :locals => {:active=>'personas', "por"=>response.body}
end

get '/indicadores' do
	

	agr = partidos()
	agr<< {"$sort"=> {"sentencias"=>-1} }
	agr <<  {"$group"=> {"_id"=>"$orgPolitica","image"=>{"$max"=>"$image"},"sentenciaPenal"=>{"$max"=>"$sentenciaPenal.idHojaVida"},
	 "sentenciaOblig"=>{"$max"=>"$sentenciaOblig.idHojaVida"}}}
                  
    agr <<  {"$project" =>  { "_id"=>1, "image"=>1, "sentenciaPenal"=> { "$setUnion"=> [ "$sentenciaPenal", [] ] },
                  "sentenciaOblig"=> { "$setUnion"=> [ "$sentenciaOblig", [] ] }
                  }}
     agr << {"$addFields"=> 
             	{ "sentenciasObligCount" => {"$sum"=> [ {"$size"=>"$sentenciaOblig"}]},
             	"sentenciasPenalCount" => {"$sum"=> [ {"$size"=>"$sentenciaPenal"}]}
             }}
	agr<< {"$sort"=> {"sentencias"=>-1} }

	sentenciados = $client[:jne].aggregate(agr, {allow_disk_use: true})

	candidatos_disueltos = $client[:jne].find({"listaCandidato.idCandidato"=>{"$in"=>disueltos()}})
				.projection(
					 {"_id"=> 0,"image"=>1,"strOrganizacionPolitica"=>1, 
					 	"listaCandidato"=> {"$elemMatch"=> {"idCandidato"=> {"$in"=> disueltos() }}}}
				)

	
	part_agr = partidos()
	part_agr<< {"$sort"=> {"orgPolitica"=>1} }
	partidos = $client[:jne].aggregate(part_agr, {allow_disk_use: true})

	tweets_arr = []

	tweets = $client[:last_tweets].aggregate([ {"$sort"=> {"tweet.created_at":-1}}, { "$limit"=>2}])
	tweets.each do |item|
		tweets_arr << item['tweet']
	end

	news_arr = []
	news = $client[:last_news].aggregate([{"$sort"=> {"date":-1}}, {"$limit"=>2}])
	news.each do |item|
		news_arr << item
	end

	erb :indicadores,:layout => :app,  :locals => {:active=>'indicadores',
				:partidos=>partidos, #menu
				:tweets=>tweets_arr,	
				:news=>news_arr,
				:candidatos_disueltos=>candidatos_disueltos,
				:sentenciados=>sentenciados

			}
end

get '/partidos' do
	

	#count = $Redis.incr( "request_count" )
	#json :count => count
	erb :index,:layout => :app,  :locals => {:active=>'partidos',"por"=>response.body}
end