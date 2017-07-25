require 'test_helper'

describe 'TemplateSection' do
  let(:template_section) do
    CompareWithWikidata::TemplateSection.new(
      original_wikitext: '{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- COMPARISON OUTPUT BEGIN -->

<!-- COMPARISON OUTPUT END -->'
    )
  end

  it 'returns a Hash of parameters' do
    template_section.named_parameters.must_equal(foo: '43', bar: 'Woolly Mountain Tapir')
  end

  it 'returns the template name' do
    template_section.template_name.must_equal('Politician scraper comparison')
  end

  it 'can be rewritten' do
    class TestRewriter
      def rewrite(parameters:, **)
        "The output is now #{parameters[:foo]}"
      end
    end
    rewritten = template_section.rewrite(TestRewriter.new)
    rewritten.original_wikitext.must_equal(
      '{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- COMPARISON OUTPUT BEGIN -->
The output is now 43
<!-- COMPARISON OUTPUT END -->'
    )
    rewritten.original_wikitext.wont_equal(template_section.original_wikitext)
  end
end
