require 'rest-client'

module MembershipList
  class Morph
    def initialize(morph_scraper:, morph_sql_query: )
      @morph_scraper = morph_scraper
      @morph_sql_query = morph_sql_query
    end

    def to_a
      morph_json_data
    end

    private

    attr_reader :morph_scraper, :morph_sql_query

    def morph_url
      unless ENV['MORPH_API_KEY']
        raise 'You must set MORPH_API_KEY in the environment'
      end
      @morph_url ||= "https://morph.io/#{morph_scraper}/data.json?key=#{ENV['MORPH_API_KEY']}&query=#{URI.encode_www_form_component(morph_sql_query)}"
    end

    def morph_json_data
      @morph_json_data ||= JSON.parse(RestClient.get(morph_url), symbolize_names: true)
    rescue RestClient::Exception => e
      raise "Morph query #{morph_sql_query.inspect} failed: #{e.message}"
    end
  end
end
