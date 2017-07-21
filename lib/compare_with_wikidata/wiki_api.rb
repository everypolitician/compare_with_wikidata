require 'mediawiki_api'

module CompareWithWikidata
  class WikiPage
    def initialize(username:, password:, title:, client_class: nil)
      @username = username
      @password = password
      @title = title
      @client_class = client_class || MediawikiApi::Client
    end

    def wikitext
      @wikitext ||= client.get_wikitext(title).body
    end

    private

    attr_accessor :username, :password, :title, :client_class

    def client
      @client ||= client_class.new('https://www.wikidata.org/w/api.php').tap do |c|
        c.log_in(ENV['WIKI_USERNAME'], ENV['WIKI_PASSWORD'])
      end
    end
  end
end
