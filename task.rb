require 'rest-client'
require 'json'
require 'gruff'
require 'uri'
require 'addressable/uri'
require 'mongo'


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
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	item = data_render['data'][0]

	for_set = {}
	item.each do |key, value|
		for_set["listaCandidato.$." + key] = value
	end
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> for_set })
end

def pushExpLaboral(hash)
	construct_id = (hash[:idHojaVida].to_s) + '-0-ASC'
	url = 'https://plataformaelectoral.jne.gob.pe/HojaVida/GetAllHVExpeLaboral?Ids='+construct_id.to_s+''.force_encoding('ASCII-8BIT')
	response = RestClient.get(url, 
	headers=headers)
	data_render = JSON.parse(response.body)
	items = data_render['data']
	$client[:jne].find({"_id" => hash[:id], "listaCandidato.idCandidato"=>hash[:idCandidato]}). 
					update_one({"$set"=> {"listaCandidato.$.expLaboral" => items} }, { :upsert => true })
end

def pushEduBasica(hash)
	#parecido al de arriba
end

#y demas


print "\n\nSTARTING APP\n"
print "-------------------\n\n"

if ARGV[0] == "partidos"

	url = 'https://plataformaelectoral.jne.gob.pe/Candidato/GetExpedientesLista/108-2-------0-'.force_encoding('ASCII-8BIT')

	response = RestClient.get(url, 
	headers=headers)
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

		$client[:jne].find(:_id => document['_id']).update_one({ '$set'=>{ :listaCandidato =>  data_render['data'] } } )
		i+=1
		print "\nGETTING "+i.to_s+"  \n"
		sleep(1.4)
	end
end


if ARGV[0] == "cvs"
	$client[:jne].find().each do |document|
		print "\n\n--\n"
		document['listaCandidato'].each do |candidato|
			idHV = candidato['idHojaVida']
			idOrg = document['idOrganizacionPolitica']
			idCandidato = candidato['idCandidato']
			pushDatosPersonales({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV, idOrganizacionPolitica:idOrg})
			pushExpLaboral({id: document['_id'],idCandidato:idCandidato, idHojaVida: idHV})
			
			break
		end
		print "\n\n--\n"

		break
	end
	#logica
end
