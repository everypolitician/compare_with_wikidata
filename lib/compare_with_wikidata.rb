require 'compare_with_wikidata/version'

require 'compare_with_wikidata/membership_list/wikidata'
require 'compare_with_wikidata/comparison'

require 'charlock_holmes/string'
require 'csv'
require 'erb'
require 'mediawiki_api'

module CompareWithWikidata
  class MalformedCSVError < StandardError
  end

  class CSVDownloadError < StandardError
  end

  class DiffOutputGenerator
    WIKI_TEMPLATE_NAME = 'Compare Wikidata with CSV'.freeze
    WIKI_USERNAME = ENV['WIKI_USERNAME']
    WIKI_PASSWORD = ENV['WIKI_PASSWORD']

    def initialize(mediawiki_site:, page_title:)
      @mediawiki_site = mediawiki_site
      @page_title = page_title.gsub('_', ' ')
    end

    def run!
      # Note that the comparison is lazily evaluated when 'comparison'
      # is evaluated from the binding in template rendering:

      always_overwrite = {
        '/stats' => 'templates/stats.erb',
        '/comparison' => 'templates/comparison.erb',
        '/_default_header_template' => 'templates/header_template.erb',
        '/_default_footer_template' => 'templates/footer_template.erb',
        '/_default_row_added_template' => 'templates/row_added.erb',
        '/_default_row_removed_template' => 'templates/row_removed.erb',
        '/_default_row_modified_template' => 'templates/row_modified.erb',
        '/_default_stats_template' => 'templates/stats_template.erb',
      }

      always_overwrite.each do |subpage, template|
        template = ERB.new(File.read(File.join(__dir__, '..', template)), nil, '-')
        dont_edit = "<!-- WARNING: This template is generated automatically. Any changes will be overwritten the next time the prompt is refreshed. -->\n"
        wikitext = dont_edit + template.result(binding)
        title = "#{page_title}#{subpage}"
        if ENV.key?('DEBUG')
          puts "# #{title}\n#{wikitext}"
        else
          client.edit(title: title, text: wikitext)
          puts "Done: Updated #{title} on #{mediawiki_site}"
        end
      end

      client.edit(title: csv_page_title, text: comparison.to_csv)

      # Apparently everything went smoothly, so overwrite the /errors
      # subpage to make sure that it's empty.
      client.edit(title: errors_page_title, text: '')

    rescue StandardError => e
      client.edit(title: errors_page_title, text: "<nowiki>#{e.message}</nowiki>")
    ensure
      # Purge the main page, so it refreshes the subpages, even if
      # there was an exception.
      client.action(:purge, titles: [page_title])
    end

    private

    attr_reader :mediawiki_site, :page_title

    def client
      abort "Please set WIKI_USERNAME and WIKI_PASSWORD" if WIKI_USERNAME.to_s.empty? || WIKI_PASSWORD.to_s.empty?
      @client ||= MediawikiApi::Client.new("https://#{mediawiki_site}/w/api.php").tap do |c|
        result = c.log_in(WIKI_USERNAME, WIKI_PASSWORD)
        unless result['result'] == 'Success'
          raise "MediawikiApi::Client#log_in failed: #{result}"
        end
      end
    end

    def errors_page_title
      "#{page_title}/errors"
    end

    def csv_page_title
      "#{page_title}/comparison_csv"
    end

    def expanded_wikitext(page_title)
      result = client.get_wikitext(page_title)
      raise "#{page_title} doesn't exist, please create it." unless result.success?
      wikitext = result.body
      result = client.action(:expandtemplates, text: wikitext, prop: :wikitext, title: page_title)
      result.data['wikitext']
    end

    def fix_encoding(s)
      return s if s.encoding == Encoding::UTF_8
      return s.encode(Encoding::UTF_8) unless s.encoding == Encoding::ASCII_8BIT
      s.dup.detect_encoding!.encode('UTF-8')
    end

    def csv_from_url(file_or_url)
      csv_text = RestClient.get(file_or_url).to_s
      CSV.parse(fix_encoding(csv_text), headers: true, header_converters: :symbol, converters: nil).map(&:to_h)
    rescue CSV::MalformedCSVError
      raise MalformedCSVError.new("The URL #{file_or_url} couldn't be parsed as CSV. Is it really a valid CSV file?")
    rescue RestClient::Exception => e
      raise CSVDownloadError.new("There was an error fetching: #{file_or_url} - the error was: #{e.message}")
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
