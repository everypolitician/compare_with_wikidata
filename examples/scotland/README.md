These are the steps taken to generate `parlparse-wikidata.csv` in this directory:

Create id mapping file using data from EP. This command was run in the [everypolitician-data](https://github.com/everypolitician/everypolitician-data) repo, from the  `data/Scotland/Parliament/sources` directory.

    (echo id,wikidata_id; jq -r '[.persons[].identifiers | map(select(.scheme == "everypolitician_legacy" or .scheme == "wikidata")) | map(.identifier) | select(length == 2)] | sort_by(.[0]) | .[] | @csv' ep-popolo-v1.0.json)

Download the parlparse output:

    curl -o /tmp/scotland-parlparse.csv https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Scotland/Parliament/sources/parlparse/data.csv

Join the id mapping file with the scraper output:

    q -H -d, -O 'select distinct w.wikidata_id as id from /tmp/scotland-parlparse.csv p inner join scotland-wikidata-ids.csv w on p.id = w.id where p.term = 4 order by wikidata_id' > parlparse-wikidata.csv
