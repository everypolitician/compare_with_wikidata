require 'test_helper'

FakeResponse = Struct.new(:body)

class FakeClient
  def initialize(*); end

  def log_in(*); end

  SAMPLE_WIKITEXT = 'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- COMPARISON OUTPUT BEGIN -->
Old content of the first section.
<!-- COMPARISON OUTPUT END -->

And some other text here before a new template:

{{Politician scraper comparison
|quux=13
|bar=Horse
}}

<!-- COMPARISON OUTPUT BEGIN -->
Old content of the second section.
<!-- COMPARISON OUTPUT END -->

Now some trailing text.'.freeze

  def get_wikitext(_title)
    FakeResponse.new(SAMPLE_WIKITEXT)
  end
end

describe 'WikiPage' do
  let(:wiki_page) do
    CompareWithWikidata::WikiPage.new(
      username: 'john', password: 's3krit', title: 'Some Wiki page', client_class: FakeClient
    )
  end

  it 'can return the wikitext for a page' do
    wiki_page.wikitext.must_match(/^Hi, here is some.*trailing text.$/m)
  end

  it 'returns two template sections' do
    wiki_page.template_sections.length.must_equal(2)
  end

  it 'returns template sections of the expected class' do
    wiki_page.template_sections[0].class.must_equal(CompareWithWikidata::TemplateSection)
  end

  it 'gives the right content to the first TemplateSection' do
    wiki_page.template_sections[0].original_wikitext.must_equal(
      '{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- COMPARISON OUTPUT BEGIN -->
Old content of the first section.
<!-- COMPARISON OUTPUT END -->'
    )
  end

  it 'gives the right content to the second TemplateSection' do
    wiki_page.template_sections[1].original_wikitext.must_equal(
      '{{Politician scraper comparison
|quux=13
|bar=Horse
}}

<!-- COMPARISON OUTPUT BEGIN -->
Old content of the second section.
<!-- COMPARISON OUTPUT END -->'
    )
  end

  it 'can be reassembled with replacement template sections' do
    wiki_page.reassemble_page(
      [
        CompareWithWikidata::TemplateSection.new(original_wikitext: 'FIRST!'),
        CompareWithWikidata::TemplateSection.new(original_wikitext: 'Second.'),
      ]
    ).must_equal(
      'Hi, here is some introductory text.

Now let\'s have a recognized template:

FIRST!

And some other text here before a new template:

Second.

Now some trailing text.'
    )
  end

  it 'can be rewritten with a "rewriter" object' do
    class TestRewriter
      def rewrite(old_content:, parameters:)
        "Preserving the old content:\n#{old_content}\n" \
        "In this template, foo is '#{parameters[:foo]}' and quux is '#{parameters[:quux]}'"
      end
    end
    wiki_page.rewrite(TestRewriter.new).must_equal(
      'Hi, here is some introductory text.

Now let\'s have a recognized template:

{{Politician scraper comparison
|foo=43
|bar=Woolly Mountain Tapir
}}

<!-- COMPARISON OUTPUT BEGIN -->
Preserving the old content:

Old content of the first section.

In this template, foo is \'43\' and quux is \'\'
<!-- COMPARISON OUTPUT END -->

And some other text here before a new template:

{{Politician scraper comparison
|quux=13
|bar=Horse
}}

<!-- COMPARISON OUTPUT BEGIN -->
Preserving the old content:

Old content of the second section.

In this template, foo is \'\' and quux is \'13\'
<!-- COMPARISON OUTPUT END -->

Now some trailing text.'
    )
  end
end
