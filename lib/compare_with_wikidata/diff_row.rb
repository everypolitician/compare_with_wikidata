require 'compare_with_wikidata/diff_row/cell'

module CompareWithWikidata
  class DiffRow
    CUSTOM_TEMPLATE_MAPPING = {
      '+++' => :row_added_template,
      '---' => :row_removed_template,
      '->'  => :row_modified_template,
    }.freeze

    def initialize(headers:, row:, params:)
      @headers = headers
      @row = row
      @params = params
    end

    def wikitext
      if custom_template
        "{{#{custom_template}|#{template_params}}}"
      else
        row.map { |c| "| #{c.to_s.gsub(/Q(\d+)/, '{{Q|\\1}}').gsub('->', ' &rarr; ')}" }.join("\n") + "\n|-\n"
      end
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

    attr_reader :headers, :row, :params

    def custom_template
      params[CUSTOM_TEMPLATE_MAPPING[change_type]]
    end

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

    def template_params
      (change_type_cell + value_cells).map { |v| v.join('=') }.join('|')
    end

    def change_type_cell
      row_as_hash.take(1)
    end

    def value_cells
      row_as_hash.drop(1).flat_map do |k, v|
        cell_class.new(key: k, value: v).cell_values
      end
    end
  end
end
