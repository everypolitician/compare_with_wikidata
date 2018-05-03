require 'mediawiki_api'

module CompareWithWikidata
  class MediawikiClient
    def initialize(mediawiki_site:, username:, password:)
      @mediawiki_site = mediawiki_site
      @username = username
      @password = password
    end

    def edit(title:, text:)
      client.edit(title: title, text: text)
    end

    def purge(titles:)
      client.action(:purge, titles: titles)
    end

    def wikitext(title:)
      client.get_wikitext(title)
    end

    def expand_templates(text:, title:)
      client.action(:expandtemplates, text: text, title: title, prop: :wikitext)
    end

    private

    attr_reader :mediawiki_site, :username, :password

    def client
      @client ||= MediawikiApi::Client.new("https://#{mediawiki_site}/w/api.php").tap do |c|
        result = c.log_in(username, password)
        raise "MediawikiApi::Client#log_in failed: #{result}" unless result['result'] == 'Success'
      end
    end
  end
end
