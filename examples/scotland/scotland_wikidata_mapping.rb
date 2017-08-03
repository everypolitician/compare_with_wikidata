require 'everypolitician'
require 'csv'

people = EveryPolitician::Index.new.country('Scotland').lower_house.popolo.persons

id_mapping = people.map do |person|
  parlparse = person.identifiers.find { |id| id[:scheme] == 'parlparse' }
  wikidata = person.identifiers.find { |id| id[:scheme] == 'wikidata' }
  [
    parlparse[:identifier].split('/').last,
    wikidata[:identifier]
  ]
end

CSV do |csv|
  csv << [:id, :wikidata_id]
  id_mapping.each { |row| csv << row }
end
