require 'test_helper'

describe 'CompareWithWikidata' do
  describe 'DiffOutputGenerator' do
    subject do
      CompareWithWikidata::DiffOutputGenerator.new(
        mediawiki_site: 'wikidata.example.com',
        page_title:     'SomePage'
      )
    end

    describe 'on instantiation' do
      it 'normalizes underscores to spaces in the page title' do
        generator = CompareWithWikidata::DiffOutputGenerator.new(
          mediawiki_site: 'wikidata.example.com',
          page_title:     'Some_interesting_page'
        )
        generator.send(:page_title).must_equal 'Some interesting page'
      end

      it 'leaves spaces intact in the page title' do
        generator = CompareWithWikidata::DiffOutputGenerator.new(
          mediawiki_site: 'wikidata.example.com',
          page_title:     'Some interesting page'
        )
        generator.send(:page_title).must_equal 'Some interesting page'
      end
    end
  end
end
