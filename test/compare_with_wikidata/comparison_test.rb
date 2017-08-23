require 'test_helper'

describe CompareWithWikidata::Comparison do
  let(:sparql_items) { [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }] }
  let(:csv_items) { [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }, { id: 3, name: 'Charlie' }] }
  subject { CompareWithWikidata::Comparison.new(sparql_items: sparql_items, csv_items: csv_items, columns: %i[id name]) }

  describe '#headers' do

    it 'returns the headers for the daff comparison' do
      subject.headers.must_equal ['@@', :id, :name]
    end
  end

  describe '#diff_rows' do
    it 'returns the correct number of rows' do
      subject.diff_rows.size.must_equal 1
    end

    it 'returns the expected number of DiffRow instances' do
      row = subject.diff_rows.first
      row.class.must_equal CompareWithWikidata::DiffRow
    end
  end
end
