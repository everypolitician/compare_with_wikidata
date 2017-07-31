# Compare with Wikidata examples

This directory contains some examples of using the prompt tool to generate diffs between external sources and Wikidata.

You can run them by `cd`ing into the directory you're interested in and running the following:

    bundle exec prompt "$(cat query.sparql)" data.csv
