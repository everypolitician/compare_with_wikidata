require 'rest-client'

module CompareWithWikidata
  module MembershipList
    class Wikidata
      WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql'.freeze

      attr_reader :sparql_query

      def initialize(sparql_query:)
        @sparql_query = sparql_query
      end

      def to_a
        @to_a ||= JSON.parse(
          sparql_response, symbolize_names: true
        )[:results][:bindings].map { |r| sparql_result_to_hash(r) }
      end

      private

      def sparql_response
        @sparql_response ||= RestClient.get WIKIDATA_SPARQL_URL, params: { query: sparql_query, format: 'json' }
      rescue RestClient::Exception => e
        raise "Wikidata query #{sparql_query.inspect} failed: #{e.message}"
      end

      def sparql_result_to_hash(sparql_result)
        url = sparql_result[:item][:value]
        item_id = url.split('/').last
        {
          item_id: item_id,
          url:     url,
          name:    sparql_result[:itemLabel][:value],
        }
      end
    end
  end
end
