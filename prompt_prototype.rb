require 'bundler/setup'
require 'json'
require 'uri'
require 'rest-client'

# FIXME: it's a bit awkward having so many positional command line
# arguments: we might want to make them named options, or for the the
# command to take a configuration file specifying them instead.

if ARGV.length < 4 || ARGV.length > 5
  abort """Usage: #{$0} EP_COUNTRY_AND_HOUSE MORPH_SCRAPER EP_ID_SCHEME WIKIDATA_MEMBERSHIP_ITEM [SCRAPER_SQL]
e.g. ruby prompt_prototype.rb Nigeria/Senate everypolitician-scrapers/nigeria-national-assembly nass Q19822359 \"SELECT * FROM data WHERE js_position = 'Sen'\"
e.g. ruby prompt_prototype.rb United_States_of_America/House tmtmtmtm/us-congress-members bioguide Q13218630
"""
end

ep_country_and_house, morph_scraper, ep_id_scheme, wikidata_membership_item, scraper_sql = ARGV
scraper_sql ||= 'SELECT * FROM data'

unless ENV['MORPH_API_KEY']
  abort "You must set MORPH_API_KEY in the environment"
end

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql'

def wikidata_sparql(query)
  result = RestClient.get WIKIDATA_SPARQL_URL, params: { query: query, format: 'json' }
  json = JSON.parse(result, symbolize_names: true)
  json[:results][:bindings].map do |res|
    url = res[:item][:value]
    item_id = url.split('/').last
    [item_id, {url: url, name: res[:itemLabel][:value]}]
  end.to_h
rescue RestClient::Exception => e
  abort "Wikidata query #{query.inspect} failed: #{e.message}"
end

def morph_records(scraper, query)
  url = "https://morph.io/#{scraper}/data.json?key=#{ENV['MORPH_API_KEY']}&query=#{URI.encode_www_form_component(query)}"
  JSON.parse(RestClient.get(url), symbolize_names: true).map { |d| [d[:id], d]  }.to_h
end

# Get an identifier's value from a Popolo person representation in JSON
def identifier(popolo_person, scheme)
  popolo_person[:identifiers].find { |i| i[:scheme] == scheme }.to_h[:identifier]
end

wikidata_records = wikidata_sparql("SELECT ?item ?itemLabel WHERE { ?item wdt:P39 wd:#{wikidata_membership_item}.  SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". } }")
morph_records = morph_records(morph_scraper, scraper_sql)

popolo_url = "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/#{ep_country_and_house}/ep-popolo-v1.0.json"
popolo = JSON.parse(RestClient.get(popolo_url).to_s, symbolize_names: true)
morph_wikidata_lookup = popolo[:persons].map { |p| [identifier(p, ep_id_scheme), identifier(p, 'wikidata')] }.to_h

morph_ids_with_wikidata, morph_ids_without_wikidata = morph_records.keys.partition do |morph_id|
  morph_wikidata_lookup[morph_id]
end

wikidate_ids_from_morph = morph_ids_with_wikidata.map { |morph_id| morph_wikidata_lookup[morph_id] }

not_in_wikidata = wikidate_ids_from_morph - wikidata_records.keys
not_in_morph = wikidata_records.keys - wikidate_ids_from_morph

puts "Records missing a P39 (position_held) of #{wikidata_membership_item}:"
wikidata_item_to_morph_id = morph_wikidata_lookup.to_a.map(&:reverse).to_h
not_in_wikidata.each do |item_id|
  morph_record = morph_records[wikidata_item_to_morph_id[item_id]]
  puts "  #{item_id} #{morph_record[:id]} #{morph_record[:name]}"
end

puts "Records not in the Morph scraper, but in Wikidata:"
not_in_morph.each do |item_id|
  wikidata_record = wikidata_records[item_id]
  puts "  #{item_id} #{wikidata_record[:url]} #{wikidata_record[:name]}"
end

puts "Records in the the Morph scraper not associated with a Wikidata item:"
morph_ids_without_wikidata.each do |morph_id|
  morph_record = morph_records[morph_id]
  puts "  #{morph_id} #{morph_record[:name]}"
end
