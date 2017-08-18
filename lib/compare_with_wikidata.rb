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

    def initialize(mediawiki_site:, page_title:)
      @mediawiki_site = mediawiki_site
      @page_title = page_title
    end

    def run!
      sparql_query = expanded_wikitext("#{page_title}/sparql")
      csv_url = expanded_wikitext("#{page_title}/csv url").strip

      wikidata_records = CompareWithWikidata::MembershipList::Wikidata.new(sparql_query: sparql_query).to_a

      external_csv = csv_from_url(csv_url)

      headers, *rows = daff_diff(wikidata_records, external_csv)
      if headers.first == '!'
        # Schema change detected
        raise 'Different schemas detected. Please ensure SPARQL query and CSV URL return the same columns.'
      end
      diff_rows = rows.reject { |r| r.first == ':' }.map { |row| CompareWithWikidata::DiffRow.new(headers: headers, row: row) }

      always_overwrite = {
        '/stats' => 'templates/stats.erb',
        '/comparison' => 'templates/comparison.erb',
      }

      overwrite_if_missing_or_empty = {
        '/header_template' => 'templates/header_template.erb',
        '/footer_template' => 'templates/footer_template.erb',
        '/row_added_template' => 'templates/row_added.erb',
        '/row_removed_template' => 'templates/row_removed.erb',
        '/row_modified_template' => 'templates/row_modified.erb',
        '/stats_template' => 'templates/stats_template.erb',
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

      overwrite_if_missing_or_empty.each do |subpage, template|
        template = ERB.new(File.read(File.join(__dir__, '..', template)), nil, '-')
        please_edit = "<!-- Feel free to edit this template. If you want to get the default back just delete the contents of the page and then refresh the prompt. -->\n"
        wikitext = please_edit + template.result(binding)
        title = "#{page_title}#{subpage}"
        result = client.get_wikitext(title)
        if !result.success? || (result.success? && result.body.strip.empty?)
          if ENV.key?('DEBUG')
            puts "# #{title}\n#{wikitext}"
          else
            client.edit(title: title, text: wikitext)
            puts "Done: Added default contents to #{title} on #{mediawiki_site}"
          end
        else
          if ENV.key?('DEBUG')
            puts "# #{title}\n#{result.body}"
          else
            puts "Page #{title} already exists"
          end
        end
      end

      # Purge the main page, so it refreshes the subpages
      client.action(:purge, titles: [page_title])
    end

    private

    attr_reader :mediawiki_site, :page_title

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
