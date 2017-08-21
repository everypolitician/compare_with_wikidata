require 'test_helper'

describe 'CompareWithWikidata' do
  describe 'MembershipList' do
    describe 'Wikidata' do
      it 'should work as expected with a valid SPARQL query' do
        stub_request(
          :get,
          'https://query.wikidata.org/sparql?query=SELECT%20?person%20?value%20' \
          'WHERE%20%7B%20wd:Q42%20wdt:P69%20?value%20BIND(wd:Q42%20as%20?person)%20%7D'
        ).to_return(
          body: "person,value\r\n" \
                "http://www.wikidata.org/entity/Q42,http://www.wikidata.org/entity/Q691283\r\n" \
                "http://www.wikidata.org/entity/Q42,http://www.wikidata.org/entity/Q4961791\r\n"
        )
        wikidata = CompareWithWikidata::MembershipList::Wikidata.new(
          sparql_query: 'SELECT ?person ?value WHERE { wd:Q42 wdt:P69 ?value BIND(wd:Q42 as ?person) }'
        )
        wikidata.to_a.must_equal [
          {
            :person=>"http://www.wikidata.org/entity/Q42",
            :value=>"http://www.wikidata.org/entity/Q691283"
          },
          {
            :person=>"http://www.wikidata.org/entity/Q42",
            :value=>"http://www.wikidata.org/entity/Q4961791"
          }
        ]
      end

      it 'produces a helpful exception message for a malformed SPARQL query' do
        stub_request(
          :get,
          'https://query.wikidata.org/sparql?query=SELECT%20?a,%20?b'
        ).to_return(
          status: [400, 'Your SPARQL was invalid']
        )
        error = assert_raises Exception do
          wikidata = CompareWithWikidata::MembershipList::Wikidata.new(
            # This is malformed because you don't use commas between
            # values in the SELECT clause in SPARQL:
            sparql_query: 'SELECT ?a, ?b'
          )
          wikidata.to_a
        end
        error.message.must_equal 'Bad Wikidata SPARQL request: most likely the query "SELECT ?a, ?b" was invalid'
      end

      it 'includes the HTTP error code for any other kind of error' do
        stub_request(
          :get,
          'https://query.wikidata.org/sparql?query=SELECT%20?value%20WHERE%20%7B%20wd:Q42%20wdt:P69%20?value%20%7D'
        ).to_return(
          status: [502, 'Workers weren\'t running or something']
        )
        error = assert_raises Exception do
          wikidata = CompareWithWikidata::MembershipList::Wikidata.new(
            sparql_query: 'SELECT ?value WHERE { wd:Q42 wdt:P69 ?value }'
          )
          wikidata.to_a
        end
        error.message.must_equal 'The Wikidata SPARQL query "SELECT ?value WHERE { wd:Q42 wdt:P69 ?value }" failed with the following error: 502 Bad Gateway'
      end
    end
  end
end
