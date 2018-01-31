require 'compare_with_wikidata/diff_row'

require 'daff'
require 'csv'
require 'charlock_holmes/string'

module CompareWithWikidata
  def self.fix_encoding(daff_table)
    daff_table.map do |row|
      row.map do |cell|
        next cell unless cell.instance_of? String
        next cell unless cell.encoding == Encoding::ASCII_8BIT
        cell.dup.detect_encoding!
      end
    end
  end

  def self.daff_diff(data1, data2)
    t1 = Daff::TableView.new(fix_encoding(data1))
    t2 = Daff::TableView.new(fix_encoding(data2))

    alignment = Daff::Coopy.compare_tables(t1, t2).align

    data_diff = []
    table_diff = Daff::TableView.new(data_diff)

    flags = Daff::CompareFlags.new
    # We don't want any context in the resulting diff
    flags.unchanged_context = 0
    flags.show_unchanged_columns = true
    highlighter = Daff::TableDiff.new(alignment, flags)
    highlighter.hilite(table_diff)

    data_diff
  end

  class Comparison
    def initialize(sparql_items:, csv_items:, columns:)
      @sparql_items = sparql_items
      @csv_items = csv_items
      @columns = columns
    end

    def headers
      daff_results.first
    end

    def diff_rows
      @diff_rows ||= rows.map { |row| DiffRow.new(headers: headers, row: row) }
    end

    def to_csv
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end
    end

    private

    attr_reader :sparql_items, :csv_items, :columns

    def daff_sparql_items
      [columns, *sparql_items.map { |r| r.values_at(*columns).map { |c| cleaned_cell(c) } }]
    end

    def daff_csv_items
      [columns, *csv_items.map { |r| r.values_at(*columns) }]
    end

    def cleaned_cell(cell)
      cell.to_s.sub(%r{^http://www.wikidata.org/entity/(Q\d+)$}, '\\1')
    end

    def daff_results
      @daff_results ||= CompareWithWikidata.daff_diff(daff_sparql_items, daff_csv_items)
    end

    # Daff diff rows, excluding moved rows (:)
    def rows
      daff_results.drop(1).reject { |r| r.first == ':' }
    end
  end
end
