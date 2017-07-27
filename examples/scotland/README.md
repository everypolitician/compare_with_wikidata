These are the steps taken to generate `parlparse-wikidata.csv` in this directory:

Create id mapping file using data from EP. This command was run in the [everypolitician-data](https://github.com/everypolitician/everypolitician-data) repo, from the  `data/Scotland/Parliament/sources` directory.

    q -H -d, -O 'select i.id, w.id as wikidata_id from idmap/data.csv i inner join reconciliation/wikidata.csv w on i.uuid = w.uuid' > path/to/scotland-wikidata-ids.csv

Download the parlparse output:

    curl -o path/to/scotland-parlparse.csv https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Scotland/Parliament/sources/parlparse/data.csv

Join the id mapping file with the scraper output:

    q -H -d, -O 'select distinct w.wikidata_id as id from scotland-parlparse.csv p inner join scotland-wikidata-ids.csv w on p.id = w.id where p.term = 4 order by wikidata_id' > parlparse-wikidata.csv
