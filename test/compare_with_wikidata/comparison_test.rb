require 'test_helper'

describe CompareWithWikidata::Comparison do
  subject { CompareWithWikidata::Comparison.new(sparql_items: sparql_items, csv_items: csv_items, columns: %i[id name]) }

  describe 'simple comparison' do
    let(:sparql_items) { [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }] }
    let(:csv_items) { [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }, { id: 3, name: 'Charlie' }] }

    it 'has the expected headers' do
      subject.headers.must_equal ['@@', :id, :name]
    end

    it 'returns the correct number of diff_rows' do
      subject.diff_rows.size.must_equal 1
    end

    it 'returns DiffRow instances from diff_rows' do
      subject.diff_rows.first.class.must_equal CompareWithWikidata::DiffRow
    end
  end

  describe 'SPARQL items with Wikidata URL prefix' do
    let(:sparql_items) do
      [
        { id: 'http://www.wikidata.org/entity/Q1' },
        { id: 'http://www.wikidata.org/entity/Q2' },
      ]
    end

    let(:csv_items) { [{ id: 'Q1' }, { id: 'Q2' }] }

    it 'ignores the Wikidata URL prefix' do
      subject.diff_rows.size.must_equal 0
    end
  end
end
