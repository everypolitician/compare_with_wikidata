require 'compare_with_wikidata/version'

require 'compare_with_wikidata/mediawiki_client'
require 'compare_with_wikidata/membership_list/wikidata'
require 'compare_with_wikidata/comparison'

require 'csv'
require 'erb'

module CompareWithWikidata
  class MalformedCSVError < StandardError
  end

  class CSVDownloadError < StandardError
  end

  class DiffOutputGenerator
    WIKI_TEMPLATE_NAME = 'Compare Wikidata with CSV'.freeze
    WIKI_USERNAME = ENV['WIKI_USERNAME']
    WIKI_PASSWORD = ENV['WIKI_PASSWORD']

    def initialize(mediawiki_client:, page_title:)
      @mediawiki_client = mediawiki_client
      @page_title = page_title.tr('_', ' ')
    end

    def run!
      # Note that the comparison is lazily evaluated when 'comparison'
      # is evaluated from the binding in template rendering:

      always_overwrite = {
        '/stats'                          => 'templates/stats.erb',
        '/comparison'                     => 'templates/comparison.erb',
        '/_default_header_template'       => 'templates/header_template.erb',
        '/_default_footer_template'       => 'templates/footer_template.erb',
        '/_default_row_added_template'    => 'templates/row_added.erb',
        '/_default_row_removed_template'  => 'templates/row_removed.erb',
        '/_default_row_modified_template' => 'templates/row_modified.erb',
        '/_default_stats_template'        => 'templates/stats_template.erb',
      }

      always_overwrite.each do |subpage, template|
        template = ERB.new(File.read(File.join(__dir__, '..', template)), nil, '-')
        dont_edit = "<!-- WARNING: This template is generated automatically. Any changes will be overwritten the next time the prompt is refreshed. -->\n"
        wikitext = dont_edit + template.result(binding)
        title = "#{page_title}#{subpage}"
        if ENV.key?('DEBUG')
          puts "# #{title}\n#{wikitext}"
        else
          mediawiki_client.edit(title: title, text: wikitext)
          puts "Done: Updated #{title} on #{mediawiki_site}"
        end
      end

      mediawiki_client.edit(title: csv_page_title, text: comparison.to_csv)

      # Apparently everything went smoothly, so overwrite the /errors
      # subpage to make sure that it's empty.
      mediawiki_client.edit(title: errors_page_title, text: '')
    ensure
      # Purge the main page, so it refreshes the subpages, even if
      # there was an exception.
      mediawiki_client.purge(titles: [page_title])
    end

    private

    attr_reader :mediawiki_client, :page_title

    def errors_page_title
      "#{page_title}/errors"
    end

    def csv_page_title
      "#{page_title}/comparison_csv"
    end

    def expanded_wikitext(page_title)
      result = mediawiki_client.wikitext(title: page_title)
      raise "#{page_title} doesn't exist, please create it." unless result.success?
      wikitext = result.body
      result = mediawiki_client.expand_templates(text: wikitext, title: page_title)
      result.data['wikitext']
    end

    def csv_from_url(file_or_url)
      CSV.parse(RestClient.get(file_or_url).to_s, headers: true, header_converters: :symbol, converters: nil).map(&:to_h)
    rescue CSV::MalformedCSVError
      raise MalformedCSVError, "The URL #{file_or_url} couldn't be parsed as CSV. Is it really a valid CSV file?"
    rescue RestClient::Exception => e
      raise CSVDownloadError, "There was an error fetching: #{file_or_url} - the error was: #{e.message}"
    end

    def sparql_query
      expanded_wikitext("#{page_title}/sparql")
    end

    def csv_url
      expanded_wikitext("#{page_title}/csv url").strip
    end

    def external_csv
      csv_from_url(csv_url)
    end

    def wikidata_records
      @wikidata_records ||= CompareWithWikidata::MembershipList::Wikidata.new(sparql_query: sparql_query).to_a
    end

    def comparison
      return @comparison if @comparison

      common_headers = wikidata_records.first.keys & external_csv.first.keys
      if common_headers.empty?
        raise 'There are no common columns between the two sources. Please ensure the SPARQL and CSV share at least one common column.'
      end

      @comparison = Comparison.new(sparql_items: wikidata_records, csv_items: external_csv, columns: common_headers)
    end
  end
end
