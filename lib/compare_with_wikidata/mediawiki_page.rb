require 'mediawiki/client'
require 'mediawiki/page'

module CompareWithWikidata
  class MediawikiPage
    WIKI_TEMPLATE_NAME = 'Compare Wikidata with CSV'.freeze
    WIKI_USERNAME = ENV['WIKI_USERNAME']
    WIKI_PASSWORD = ENV['WIKI_PASSWORD']

    def initialize(mediawiki_site:, page_title:)
      @mediawiki_site = mediawiki_site
      @page_title = page_title
    end

    def params
      wikipage_section.params
    end

    def replace_output(wikitext)
      wikipage_section.replace_output(wikitext, "Update templates at #{DateTime.now}")
    end

    private

    attr_reader :mediawiki_site, :page_title

    def wikipage_section
      @wikipage_section ||= MediaWiki::Page::ReplaceableContent.new(
        client:   mediawiki_client,
        title:    page_title,
        template: WIKI_TEMPLATE_NAME
      )
    end

    def mediawiki_client
      @mediawiki_client ||= MediaWiki::Client.new(
        site:     mediawiki_site,
        username: WIKI_USERNAME,
        password: WIKI_PASSWORD
      )
    end
  end
end
