require 'csv'
require 'rest-client'

module CompareWithWikidata
  class MalformedCSVError < StandardError
  end

  class CSVDownloadError < StandardError
  end

  class CSVFromURL
    def initialize(file_or_url)
      @file_or_url = file_or_url
    end

    def parsed
      CSV.parse(csv_text, headers: true, header_converters: :symbol, converters: nil).map(&:to_h)
    rescue CSV::MalformedCSVError
      raise MalformedCSVError, "The URL #{file_or_url} couldn't be parsed as CSV. Is it really a valid CSV file?"
    end

    private

    attr_reader :file_or_url

    def csv_text
      RestClient.get(file_or_url).to_s
    rescue RestClient::Exception => e
      raise CSVDownloadError, "There was an error fetching: #{file_or_url} - the error was: #{e.message}"
    end
  end
end
