require 'compare_with_wikidata/version'

require 'compare_with_wikidata/diff_row'
require 'compare_with_wikidata/membership_list/wikidata'

require 'daff'
require 'csv'
require 'erb'
require 'mediawiki/client'
require 'mediawiki/page'

module CompareWithWikidata
  WIKI_TEMPLATE_NAME = 'Compare Wikidata with CSV'.freeze
  WIKI_USERNAME = ENV['WIKI_USERNAME']
  WIKI_PASSWORD = ENV['WIKI_PASSWORD']

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

  def compare_with_wikidata(mediawiki_site, page_title)
    client = MediaWiki::Client.new(
      site:     mediawiki_site,
      username: WIKI_USERNAME,
      password: WIKI_PASSWORD
    )

    # FIXME: Ideally this would use the Expandtemplates API, rather than gsub.
    # https://github.com/everypolitician/mediawiki-page-replaceable_content/issues/3
    sparql_query_wikitext = client.get_wikitext("#{page_title}/sparql").body
    csv_url_wikitext = client.get_wikitext("#{page_title}/csv_url").body

    sparql_query = client.send(:wrapped_client).action(:expandtemplates, text: sparql_query_wikitext, prop: :wikitext, title: page_title).data['wikitext']
    csv_url = client.send(:wrapped_client).action(:expandtemplates, text: csv_url_wikitext, prop: :wikitext, title: page_title).data['wikitext'].strip

    params = {}
    %i(header_template footer_template row_added_template row_removed_template row_modified_template).each do |t|
      response = client.get_wikitext("#{page_title}/#{t}")
      if response.success?
        params[t] = "/#{t}"
      end
    end

    wikidata_records = CompareWithWikidata::MembershipList::Wikidata.new(sparql_query: sparql_query).to_a

    external_csv = csv_from_url(csv_url)

    headers, *rows = daff_diff(wikidata_records, external_csv)
    diff_rows = rows.map { |row| CompareWithWikidata::DiffRow.new(headers: headers, row: row, params: params) }
    template = ERB.new(File.read(File.join(__dir__, '..', 'templates/mediawiki.erb')), nil, '-')
    wikitext = template.result(binding)

    if ENV.key?('DEBUG')
      puts wikitext
    else
      client.edit(title: "#{page_title}/output", text: wikitext)
      client.send(:wrapped_client).action(:purge, titles: [page_title])
      puts "Done: Updated #{page_title}/output on #{mediawiki_site}"
    end
  end
end
