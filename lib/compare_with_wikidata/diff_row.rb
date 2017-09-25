require 'compare_with_wikidata/diff_row/cell'

module CompareWithWikidata
  class DiffRow
    def initialize(headers:, row:)
      @headers = headers
      @row = row
    end

    def type
      {
        '+++' => 'row_added',
        '---' => 'row_removed',
        '->' => 'row_modified',
      }[change_type]
    end

    def template_params
      (change_type_cell + value_cells).map { |v| v.join('=') }.join('|')
    end

    def addition?
      change_type == '+++'
    end

    def removal?
      change_type == '---'
    end

    def modification?
      change_type == '->'
    end

    private

    attr_reader :headers, :row

    def row_as_hash
      headers.zip(row).to_h
    end

    def change_type
      row_as_hash['@@']
    end

    def cell_class
      if modification?
        CellModified
      elsif addition?
        CellAdded
      elsif removal?
        CellRemoved
      else
        raise "Unknown change type: #{change_type}"
      end
    end

    def change_type_cell
      row_as_hash.take(1)
    end

    def templatize_if_item_id(s)
      s.sub(/^Q(\d+)$/, '{{Q|\\1}}')
    end

    def value_cells
      row_as_hash.drop(1).flat_map do |k, v|
        value = v.to_s.sub('http://www.wikidata.org/entity/', '')
        # Expand Wikidata item IDs to templated versions. (These might
        # be on either side of a '->' if the cell represents a change.)
        value = value.split('->').map { |e| templatize_if_item_id(e) }.join('->')
        cell_class.new(key: k, value: value).cell_values
      end
    end
  end
end
