require 'test_helper'

describe 'CompareWithWikidata::daff_diff' do
  it 'should cope with nil entries on the left' do
    CompareWithWikidata.daff_diff(
      [[:name], [nil]],
      [[:name], ['Joan']]
    ).must_equal [['@@', :name], ['+++', 'Joan'], ['---', nil]]
  end

  it 'should cope with nil entries on the right' do
    CompareWithWikidata.daff_diff(
      [[:name], ['Joan']],
      [[:name], [nil]]
    ).must_equal [['@@', :name], ['+++', nil], ['---', 'Joan']]
  end

  it 'should not throw an exception comparing ISO-8859-1 and UTF-8' do
    CompareWithWikidata.daff_diff(
      [[:name], ['Jöan'.encode(Encoding::ISO8859_1)]],
      [[:name], ['Jøan']]
    )
  end

  it 'should not throw an exception comparing ASCII-8BIT and UTF-8' do
    joan_latin1 = 'Jöan'.encode(Encoding::ISO8859_1)
    CompareWithWikidata.daff_diff(
      [[:name], [joan_latin1.force_encoding(Encoding::ASCII_8BIT)]],
      [[:name], ['Jøan']]
    )
  end
end
