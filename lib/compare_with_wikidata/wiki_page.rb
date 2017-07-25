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

    def reassemble_page(new_template_sections)
      unless new_template_sections.length == template_sections.length
        raise 'When reassembling a page, you must supply the same number ' \
              'of template sections as there were originally ' \
              "(#{template_sections})"
      end
      non_template_sections.zip(
        new_template_sections.map(&:original_wikitext)
      ).flatten.join('')
    end

    def template_sections
      @template_sections ||= wikitext.scan(TemplateSection::TEMPLATE_RE_NO_GROUPS).map do |s|
        TemplateSection.new(original_wikitext: s)
      end
    end

    def non_template_sections
      @non_template_sections ||= wikitext.split(TemplateSection::TEMPLATE_RE_NO_GROUPS)
    end

    def rewrite(rewriter)
      rewritten_template_sections = template_sections.map do |template_section|
        template_section.rewrite(rewriter)
      end
      reassemble_page(rewritten_template_sections)
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
