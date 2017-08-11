require 'compare_with_wikidata/version'

require 'compare_with_wikidata/diff_row'
require 'compare_with_wikidata/membership_list/wikidata'

require 'daff'
require 'csv'
require 'erb'
require 'mediawiki_api'

module CompareWithWikidata
  class DiffOutputGenerator
    WIKI_TEMPLATE_NAME = 'Compare Wikidata with CSV'.freeze
    WIKI_USERNAME = ENV['WIKI_USERNAME']
    WIKI_PASSWORD = ENV['WIKI_PASSWORD']

    def initialize(mediawiki_site:, page_title:, **params)
      @mediawiki_site = mediawiki_site
      @page_title = page_title
      @params = params
    end

    def run!
      sparql_query = expanded_wikitext("#{page_title}/sparql")
      csv_url = expanded_wikitext("#{page_title}/csv url").strip

      wikidata_records = CompareWithWikidata::MembershipList::Wikidata.new(sparql_query: sparql_query).to_a

      external_csv = csv_from_url(csv_url)

      headers, *rows = daff_diff(wikidata_records, external_csv)
      diff_rows = rows.map { |row| CompareWithWikidata::DiffRow.new(headers: headers, row: row, params: params) }
      comparison_template = ERB.new(File.read(File.join(__dir__, '..', 'templates/comparison.erb')), nil, '-')
      stats_template = ERB.new(File.read(File.join(__dir__, '..', 'templates/stats.erb')), nil, '-')
      output_wikitext = comparison_template.result(binding)
      stats_wikitext = stats_template.result(binding)

      if ENV.key?('DEBUG')
        puts stats_wikitext
        puts output_wikitext
      else
        client.edit(title: "#{page_title}/comparison", text: output_wikitext)
        client.edit(title: "#{page_title}/stats", text: stats_wikitext)
        client.action(:purge, titles: [page_title])
        puts "Done: Updated #{page_title} on #{mediawiki_site}"
      end
    end

    private

    attr_reader :mediawiki_site, :page_title, :params

    def client
      @client ||= MediawikiApi::Client.new("https://#{mediawiki_site}/w/api.php").tap do |c|
        result = c.log_in(WIKI_USERNAME, WIKI_PASSWORD)
        unless result['result'] == 'Success'
          raise "MediawikiApi::Client#log_in failed: #{result}"
        end
      end
    end

    def expanded_wikitext(page_title)
      result = client.get_wikitext(page_title)
      raise "#{page_title} doesn't exist, please create it." unless result.success?
      wikitext = result.body
      result = client.action(:expandtemplates, text: wikitext, prop: :wikitext, title: page_title)
      result.data['wikitext']
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
