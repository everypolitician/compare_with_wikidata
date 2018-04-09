require 'test_helper'

describe 'CompareWithWikidata' do
  describe 'DiffOutputGenerator' do
    subject do
      CompareWithWikidata::DiffOutputGenerator.new(
        mediawiki_site: 'wikidata.example.com',
        page_title:     'SomePage'
      )
    end

    describe 'csv_from_url' do
      it 'should produce a sensible response from genuine CSV' do
        stub_request(:get, 'http://example.com/real.csv').to_return(
          body: %(heading A,"heading B",heading C\r\n1,2,3\r\n)
        )
        result = subject.send(:csv_from_url, 'http://example.com/real.csv')
        result.must_equal [
          { heading_a: '1', heading_b: '2', heading_c: '3' },
        ]
      end

      it 'should produce a helpful exception message on a 404 error' do
        stub_request(:get, 'http://example.com/non-existent').to_return(
          status: [404, 'No file found. Nothing at all.']
        )
        error = assert_raises Exception do
          subject.send(:csv_from_url, 'http://example.com/non-existent')
        end
        error.message.must_equal 'There was an error fetching: http://example.com/non-existent - the error was: 404 Not Found'
      end

      it 'should produce a helpful exception message on a 404 error' do
        stub_request(:get, 'http://example.com/errors').to_return(
          status: [500, 'Our fault. Not your fault.']
        )
        error = assert_raises Exception do
          subject.send(:csv_from_url, 'http://example.com/errors')
        end
        error.message.must_equal 'There was an error fetching: http://example.com/errors - the error was: 500 Internal Server Error'
      end

      it 'should parse a minimal HTML document without commas or quotes as a single column' do
        # This is a weird example, but some minimal valid HTML
        # documents are also valid single column CSV files, and we
        # should interpret them as such if possible:
        stub_request(:get, 'http://example.com/html-but-also-valid-csv.csv').to_return(
          body: '<!doctype html>
<html lang=en>
  <head>
    <meta charset=utf-8>
    <title>A minimal HTML document.</title>
  </head>
  <body><p></p>
  </body>
</html>
'
        )
        result = subject.send(:csv_from_url, 'http://example.com/html-but-also-valid-csv.csv')
        result.must_equal [
          { doctype_html: '<html lang=en>' },
          { doctype_html: '  <head>' },
          { doctype_html: '    <meta charset=utf-8>' },
          { doctype_html: '    <title>A minimal HTML document.</title>' },
          { doctype_html: '  </head>' },
          { doctype_html: '  <body><p></p>' },
          { doctype_html: '  </body>' },
          { doctype_html: '</html>' },
        ]
      end

      it 'should raise an appropriate custom error on non-CSV containing mid-line quotes' do
        # The quotes will cause the CSV reader to raise:
        #   CSV::MalformedCSVError: Illegal quoting in line 5.
        # ... which we should catch and turn into a more friendly
        # error.
        stub_request(:get, 'http://example.com/not-really-csv.csv').to_return(
          body: '<!doctype html>
<html lang=en>
  <head>
    <meta charset=utf-8>
    <title>A minimal HTML that contains some "quotation marks".</title>
  </head>
</html>
'
        )
        error = assert_raises CompareWithWikidata::MalformedCSVError do
          subject.send(:csv_from_url, 'http://example.com/not-really-csv.csv')
        end
        error.message.must_equal "The URL http://example.com/not-really-csv.csv couldn't be parsed as CSV. Is it really a valid CSV file?"
      end
    end

    describe 'on instantiation' do
      it 'normalizes underscores to spaces in the page title' do
        generator = CompareWithWikidata::DiffOutputGenerator.new(
          mediawiki_site: 'wikidata.example.com',
          page_title:     'Some_interesting_page'
        )
        generator.send(:page_title).must_equal 'Some interesting page'
      end

      it 'leaves spaces intact in the page title' do
        generator = CompareWithWikidata::DiffOutputGenerator.new(
          mediawiki_site: 'wikidata.example.com',
          page_title:     'Some interesting page'
        )
        generator.send(:page_title).must_equal 'Some interesting page'
      end
    end
  end
end
