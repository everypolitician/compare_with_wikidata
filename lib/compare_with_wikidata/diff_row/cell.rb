module CompareWithWikidata
  class DiffRow
    class Cell
      def initialize(key:, value:)
        @key = key
        @raw_value = value
      end

      def cell_values
        [
          [key, value],
          ["#{key}_sparql", sparql_value],
          ["#{key}_csv", csv_value],
        ]
      end

      private

      attr_reader :key, :raw_value

      def value
        CellValue.new(raw_value).templatized
      end
    end

    class CellValue < String
      def templatized
        sub('http://www.wikidata.org/entity/', '').sub(/^Q(\d+)$/, '{{Q|\\1}}')
      end
    end

    class CellAdded < Cell
      def sparql_value
        nil
      end

      def csv_value
        value
      end
    end

    class CellRemoved < Cell
      def sparql_value
        value
      end

      def csv_value
        nil
      end
    end

    class CellModified < Cell
      def sparql_value
        CellValue.new(split_value.first).templatized
      end

      def csv_value
        CellValue.new(split_value.last).templatized
      end

      def value
        [sparql_value, csv_value].join(separator)
      end

      private

      def separator
        '->'
      end

      def split_value
        raw_value.split(separator, 2)
      end
    end
  end
end
