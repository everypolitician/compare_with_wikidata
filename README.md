# CompareWithWikidata

Library for diffing Wikidata SPARQL queries with CSVs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'compare_with_wikidata', github: 'everypolitician/compare_with_wikidata'
```

And then execute:

    $ bundle

## Usage

### Update a prompt on a given page

```ruby
CompareWithWikidata::DiffOutputGenerator.new(
  mediawiki_site: 'www.wikidata.org',
  page_title: 'User:Chris_Mytton/sandbox/prompts/heads_of_government'
).run!
```

This will look for `/sparql` and `/csv_url` subpages under the provided page and use those as the inputs for the comparison. It will then write the output to a `/comparison` subpage and some stats to a `/stats` subpage.

As part of this process we also create some default templates that allow you to customize the look of a prompt. You can find links to these subpages in the "Customize" section of a prompt page.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Test coverage

When you run the tests with `rake test` a coverage report is automatically generated in the `coverage/` directory in the root of the project. Open `coverage/index.html` in a browser to view the coverage report.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/compare_with_wikidata.

