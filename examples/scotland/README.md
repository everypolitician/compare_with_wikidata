These are the steps taken to generate `parlparse-wikidata.csv` in this directory:

Create id mapping file using data from EveryPolitician:

    ruby scotland_wikidata_mapping.rb > /tmp/scotland-wikidata-ids.csv

Download the parlparse output from everypolitician-data:

    curl -o /tmp/scotland-parlparse.csv https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Scotland/Parliament/sources/parlparse/data.csv

Join the id mapping file with the scraper output:

    for term in 1 2 3 4 5; do
      q -H -d, -O "select distinct w.wikidata_id as id from /tmp/scotland-parlparse.csv p inner join /tmp/scotland-wikidata-ids.csv w on p.id = w.id where p.term = $term order by wikidata_id" > term-$term/data.csv
    done
