require 'test_helper'

describe CompareWithWikidata::DiffRow do
  describe 'simple comparison' do
    subject { CompareWithWikidata::DiffRow.new(headers: headers, row: row) }
    let(:headers) { %w[@@ id name] }

    describe 'when only the name changes' do
      let(:row) { ['->', '2', 'Bob->Bobby'] }
      it 'only has a change in a single cell' do
        subject.template_params.must_equal '@@=->|id=2|id_sparql=2|id_csv=2|name=Bob->Bobby|name_sparql=Bob|name_csv=Bobby'
      end
    end
  end

  describe 'cells containing Q values' do
    it 'replaces them if they span the entire cell' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ name], row: %w[+++ Q42])
      row.template_params.must_equal '@@=+++|name={{Q|42}}|name_sparql=|name_csv={{Q|42}}'
    end

    it "doesn't replace Q values that appear with other text in a cell" do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ name], row: ['+++', 'Douglas Adams (Q42)'])
      row.template_params.must_equal '@@=+++|name=Douglas Adams (Q42)|name_sparql=|name_csv=Douglas Adams (Q42)'
    end

    it 'handles cells that contain a change in Q value' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ item], row: ['->', 'Q3510833->Q1572486'])
      row.template_params.must_equal '@@=->|item={{Q|3510833}}->{{Q|1572486}}|item_sparql={{Q|3510833}}|item_csv={{Q|1572486}}'
    end

    it 'handles cells where a Q value changes to NULL' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ item], row: ['->', 'Q3510833->NULL'])
      row.template_params.must_equal '@@=->|item={{Q|3510833}}->NULL|item_sparql={{Q|3510833}}|item_csv=NULL'
    end

    it 'handles cells where NULL changes to a Q value' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ item], row: ['->', 'NULL->Q1572486'])
      row.template_params.must_equal '@@=->|item=NULL->{{Q|1572486}}|item_sparql=NULL|item_csv={{Q|1572486}}'
    end

    it 'handles cells with a blank value' do
      row = CompareWithWikidata::DiffRow.new(headers: %w[@@ start_date], row: ['->', ''])
      row.template_params.must_equal '@@=->|start_date=|start_date_sparql=|start_date_csv='
    end
  end
end
