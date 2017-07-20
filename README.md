# CompareWithWikidata

This tool takes a particular page on wikidata.org, looks for two
particular templates (`Politician scraper comparison` and
`Politician scraper comparison end`), extracts parameters from the
opening template and uses those parameters to generate a report
between those templates which indicates discrepancies between a
list of politicians in Wikidata and those from a Morph scraper.

The output of this tool will be improved in the future, but at
the moment, we expected it to produce three lists as follows:

```mediawiki
== Records matched to Wikidata but not returned by SPARQL query ==
* {{Q|25753711}} 849 ABUBAKAR KYARI
* {{Q|28600192}} 511 ALIMIKHENA ASEKHAME FRANCIS
* {{Q|23765700}} 888 BASSEY ALBERT AKPAN
== Records not in the Morph scraper, but in Wikidata ==
* {{Q|339008}}
* {{Q|378378}}
== Records in the the Morph scraper not associated with a Wikidata item ==
* 771 ABDULFATAI BUHARI
* 944 Abdullahi Abubakar Gumel
* 500 ABDULLAHI DANBABA IBRAHIM
* 811 ABUBAKAR DANLADI SANI
```

TODO:

* At the moment this tool must be manually passed the page to
  rewrite - in the future we would want it to find all pages
  that include these templates, as
  [Listeria](https://tools.wmflabs.org/listeria/) does, and
  process all of them in the same way.
* We might want instead to have separate templates for the
  different types of discrepancy that this tool reports on
  (e.g. person in Morph not found in Wikidata, person in
  Wikidata not found in morph, etc.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'compare_with_wikidata'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install compare_with_wikidata

## Usage

You must set the environment variable `MORPH_API_KEY` to a valid
Morph API key in order for this script to work.

The script that rewrites the page would be invoked as:

    bundle exec prompt https://www.wikidata.org/wiki/Talk:Q123456789

The syntax of the two template tags that must be in the page are
as follows:

### Mapping comes from EveryPolitician Popolo identifier

This uses the identifier from EveryPolitician's Popolo JSON to map people
from the scraper to Wikidata items.

    {{Politician scraper comparison
    |sparql=<WIKIDATA-SPARQL-QUERY>
    |morph_scraper=<MORPH-SCRAPER>
    |morph_sql=<MORPH-SQL-QUERY>
    |everypolitician_slug=<EVERYPOLITICIAN-SLUG>
    |everypolitician_id_scheme=<EVERYPOLITICIAN-IDENTIFIER-SCHEME>
    }}

    {{Politician scraper comparison end}}

### Mapping comes from Wikidata property

This allows you to specify a Wikidata property that represents an external
identifier which maps to the `id` column of the scraper.

    {{Politician scraper comparison
    |sparql=<WIKIDATA-SPARQL-QUERY>
    |morph_scraper=<MORPH-SCRAPER>
    |morph_sql=<MORPH-SQL-QUERY>
    |wikidata_identifier_property_id=<WIKIDATA-IDENTIFIER-PROPERTY-ID>
    }}

    {{Politician scraper comparison end}}

### No mapping, scraper contains Wikidata IDs

This allows you to use a scraper which has a column containing a Wikidata ID.

    {{Politician scraper comparison
    |sparql=<WIKIDATA-SPARQL-QUERY>
    |morph_scraper=<MORPH-SCRAPER>
    |morph_sql=<MORPH-SQL-QUERY>
    |morph_wikidata_identifier_column=<MORPH-WIKIDATA-IDENTIFIER-COLUMN>
    }}

    {{Politician scraper comparison end}}

### Template parameters

The meaning of the parameters above is as follows:

* **WIKIDATA-SPARQL-QUERY**: this query should find all the
  Wikidata items you want to compare, and have both `?item`
  and `?itemLabel` in the `SELECT` clause.

* **MORPH-SCRAPER**: This is the slug of the Morph scraper,
  e.g. `tmtmtmtm/us-congress-members`
* **MORPH-SQL-QUERY**: This is the SQL query that extracts the
  membership data from the Morph scraper. If omitted, this
  defaults to `SELECT * FROM data`.

* **EVERYPOLITICIAN-SLUG**: This is the country and house
  slugs from EveryPolitician joined with a `/`. For example, for
  the House of Representatives in the USA, that would be
  `United-States-of-America/House`.
* **EVERYPOLITICIAN-IDENTIFIER-SCHEME**: This is the scheme of
  the identifier in EveryPolitician which corresponds to the
  `id` column of the Morph scraper.

* **WIKIDATA-IDENTIFIER-PROPERTY-ID**: The Wikidata property
  representing an external identifier that maps to the `id`
  column of the scraper.

For example, to generate a comparison of Nigerian Senators
between the EveryPolitician Morph scraper of the Nigerian
National Assembly website, and data on Nigerian Senators in
Wikidata, one might use:

    {{Politician scraper comparison
    |sparql=SELECT ?item ?itemLabel WHERE {
      ?item wdt:P39 wd:Q19822359.
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    |everypolitician_slug=Nigeria/Senate
    |morph_scraper=everypolitician-scrapers/nigeria-national-assembly
    |everypolitician_id_scheme=nass
    |morph_sql=SELECT * FROM data WHERE js_position = 'Sen'
    }}
    This text will be replaced with the comparison generated by
    this tool.
    {{Politician scraper comparison end}}

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/compare_with_wikidata.
