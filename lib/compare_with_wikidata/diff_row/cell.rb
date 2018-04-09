module CompareWithWikidata
  class DiffRow
    class Cell
      def initialize(key:, value:)
        @key = key
        @value = value
      end

      def cell_values
        [
          [key, value],
          ["#{key}_sparql", sparql_value],
          ["#{key}_csv", csv_value],
        ]
      end

      private

      attr_reader :key, :value
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
        split_value.first
      end

      def csv_value
        split_value.last
      end

      private

      def split_value
        value.split('->', 2)
      end
    end
  end
end
