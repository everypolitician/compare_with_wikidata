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
        # Expand Wikidata item IDs to templated versions. (These might
        # be on either side of a '->' if the cell represents a change.)
        #   TODO: handle that case separately in CellModified
        raw_value.to_s.sub('http://www.wikidata.org/entity/', '')
                 .split('->').map { |e| templatize_if_item_id(e) }.join('->')
      end

      # TODO: move this onto String or a suitable subclass
      #  (possibly create a Value class to handle it)
      def templatize_if_item_id(string)
        string.sub(/^Q(\d+)$/, '{{Q|\\1}}')
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
