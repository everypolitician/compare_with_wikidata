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
end
