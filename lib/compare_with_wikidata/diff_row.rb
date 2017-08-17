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

    def template_params
      (row_as_hash.take(1) + row_as_hash.to_a.drop(1).flat_map do |k, v|
        if modification?
          if v.include?('->')
            sparql_v, csv_v = v.split('->')
          else
            sparql_v, csv_v = v, v
          end
        elsif addition?
          sparql_v = nil
          csv_v = v
        elsif removal?
          sparql_v = v
          csv_v = nil
        end
        [
          [k, v],
          ["#{k}_sparql", sparql_v],
          ["#{k}_csv", csv_v]
        ]
      end).map { |v| v.join('=') }.join('|')
    end
  end
end
