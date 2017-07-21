module CompareWithWikidata
  class TemplateSection
    def initialize(original_wikitext)
      @original_wikitext = original_wikitext
    end

    attr_accessor :original_wikitext
  end
end
