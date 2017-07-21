require 'test_helper'

FakeResponse = Struct.new(:body)

class FakeClient
  def initialize(*); end

  def log_in(*); end

  def get_wikitext(title)
    FakeResponse.new('Foo bar')
  end
end

describe 'WikiPage' do
  it 'can be initialized with a username, password and title' do
    CompareWithWikidata::WikiPage.new(
      username: 'john', password: 's3krit', title: 'Some Wiki page'
    )
  end

  it 'can return the wikitext for a page' do

    wiki_page = CompareWithWikidata::WikiPage.new(
      username: 'john', password: 's3krit', title: 'Some Wiki page', client_class: FakeClient
    )
    wiki_page.wikitext.must_equal('Foo bar')
  end
end
