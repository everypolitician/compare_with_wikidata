require 'csv'
require 'daff'
require 'erb'

module CompareWithWikidata
  class MediawikiText
    def initialize(mediawiki_page:)
      @mediawiki_page = mediawiki_page
    end

    def to_s
      headers, *rows = daff_diff(wikidata_records, external_csv)
      diff_rows = rows.map do |row|
        CompareWithWikidata::DiffRow.new(headers: headers, row: row, params: mediawiki_page.params)
      end
      template = ERB.new(File.read(File.join(__dir__, '..', '..', 'templates/mediawiki.erb')), nil, '-')
      template.result(binding)
    end

    private

    attr_reader :mediawiki_page

    def wikidata_records
      @wikidata_records ||= CompareWithWikidata::MembershipList::Wikidata.new(sparql_query: sparql).to_a
    end

    def external_csv
      @external_csv ||= csv_from_url(csv_url)
    end

    def sparql
      mediawiki_page.params[:sparql]
    end

    def csv_url
      mediawiki_page.params[:csv_url]
    end

    def daff_diff(data1, data2)
      t1 = Daff::TableView.new(data1)
      t2 = Daff::TableView.new(data2)

      alignment = Daff::Coopy.compare_tables(t1, t2).align

      data_diff = []
      table_diff = Daff::TableView.new(data_diff)

      flags = Daff::CompareFlags.new
      # We don't want any context in the resulting diff
      flags.unchanged_context = 0
      highlighter = Daff::TableDiff.new(alignment, flags)
      highlighter.hilite(table_diff)

      data_diff
    end

    def csv_from_url(file_or_url)
      if File.exist?(file_or_url)
        CSV.read(file_or_url)
      else
        CSV.parse(RestClient.get(file_or_url).to_s)
      end
    end
  end
end
