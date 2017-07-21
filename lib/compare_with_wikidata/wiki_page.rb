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

    def template_sections
      section_re = /
        \{\{Politician\ scraper\ comparison
        .*?
        <!--\ COMPARISON\ OUTPUT\ BEGIN\ -->
        .*?
        <!--\ COMPARISON\ OUTPUT\ END\ -->/xm
      wikitext.scan(section_re).map do |matched_text|
        TemplateSection.new(matched_text)
      end
    end

    private

    attr_accessor :username, :password, :title, :client_class

    def client
      @client ||= client_class.new('https://www.wikidata.org/w/api.php').tap do |c|
        c.log_in(username, password)
      end
    end
  end
end
