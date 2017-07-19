require 'bundler/setup'
require 'json'

require_relative 'lib/membership_list/morph'
require_relative 'lib/membership_list/wikidata'
require_relative 'lib/mapping/ep_identifier_to_wikidata'

# FIXME: it's a bit awkward having so many positional command line
# arguments: we might want to make them named options, or for the the
# command to take a configuration file specifying them instead.

if ARGV.length < 4 || ARGV.length > 5
  abort """Usage: #{$0} EP_COUNTRY_AND_HOUSE MORPH_SCRAPER EP_ID_SCHEME WIKIDATA_MEMBERSHIP_ITEM [SCRAPER_SQL]
e.g. ruby prompt_prototype.rb Nigeria/Senate everypolitician-scrapers/nigeria-national-assembly nass Q19822359 \"SELECT * FROM data WHERE js_position = 'Sen'\"
e.g. ruby prompt_prototype.rb United-States-of-America/House tmtmtmtm/us-congress-members bioguide Q13218630
"""
end

ep_country_and_house, morph_scraper, ep_id_scheme, wikidata_membership_item, scraper_sql = ARGV
scraper_sql ||= 'SELECT * FROM data'

morph_list = MembershipList::Morph.new(
  morph_scraper: morph_scraper,
  morph_sql_query: scraper_sql
)

morph_records = morph_list.to_a.map { |d| [d[:id], d] }.to_h

wikidata_list = MembershipList::Wikidata.new(
  wikidata_membership_item: wikidata_membership_item
)

wikidata_records = wikidata_list.to_a.map { |h| [h[:item_id], h] }.to_h

morph_wikidata_lookup = Mapping::EPIdentifierToWikidata.new(
  ep_slug: ep_country_and_house, ep_id_scheme: ep_id_scheme
).to_h

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
