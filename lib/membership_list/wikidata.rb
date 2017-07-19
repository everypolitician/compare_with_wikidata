require 'rest-client'

module MembershipList
  class Wikidata
    WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql'.freeze

    def initialize(wikidata_membership_item:)
      @wikidata_membership_item = wikidata_membership_item
    end

    def to_a
      @to_a ||= JSON.parse(
        sparql_response, symbolize_names: true
      )[:results][:bindings].map { |r| sparql_result_to_hash(r) }
    end

    private

    attr_reader :wikidata_membership_item

    def sparql_query
      @sparql_query ||= """
        SELECT ?item ?itemLabel
          WHERE {
            ?item wdt:P39 wd:#{wikidata_membership_item}.
            SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }
          }
"""
    end

    def sparql_response
      @sparql_response ||= RestClient.get WIKIDATA_SPARQL_URL, params: { query: sparql_query, format: 'json' }
    rescue RestClient::Exception => e
      raise "Wikidata query #{query.inspect} failed: #{e.message}"
    end

    def sparql_result_to_hash(sparql_result)
      url = sparql_result[:item][:value]
      item_id = url.split('/').last
      {
        item_id: item_id,
        url: url,
        name: sparql_result[:itemLabel][:value]
      }
    end
  end
end
