require 'test_helper'

describe CompareWithWikidata::DiffRow do
  describe 'cells containing Q values' do
    it 'replaces them if they span the entire cell' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ name], row: %w[+++ Q42])
      row.template_params.must_equal '@@=+++|name={{Q|42}}|name_sparql=|name_csv={{Q|42}}'
    end

    it "doesn't replace Q values that appear with other text in a cell" do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ name], row: ['+++', 'Douglas Adams (Q42)'])
      row.template_params.must_equal '@@=+++|name=Douglas Adams (Q42)|name_sparql=|name_csv=Douglas Adams (Q42)'
    end
  end
end
