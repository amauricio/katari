#encoding: utf-8

require 'sinatra'
require 'json'
require 'redis'
require 'rest-client'
require 'gruff'
require 'uri'
require 'addressable/uri'
require 'mongo'
require 'active_support/inflector'
require 'open-uri'
require 'rss'

Mongo::Logger.logger = Logger.new('mongo.public.log')
$client = Mongo::Client.new([ 'katari_mongo:27017' ], :database => 'remote')

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


def base()
	return [
			 
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
	agr = [
			 
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

	   page = 1
	   if (params[:page].to_i) > 0
	   		page = (params[:page].to_i-1)
	   end

	   agr<<{ "$sort"=> {"orgPolitica"=>1} }
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
	   agr<<{ "$sort"=> {"expLaboral.strAnioTrabajoDesde"=>-1} }
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
		content_type 'image/png'
		Base64.decode64("R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==")
	end
end

get '/' do
	
	erb :personas,:layout => :app,  :locals => {:active=>'personas', "por"=>response.body}
end

get '/partidos' do
	

	#count = $Redis.incr( "request_count" )
	#json :count => count
	erb :index,:layout => :app,  :locals => {:active=>'partidos',"por"=>response.body}
end