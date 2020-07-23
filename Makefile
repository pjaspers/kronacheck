build: fetch today-twitterpp today-all full-csv

fetch:
	bin/krona fetch
today-twitterpp:
	bin/krona --output html --filename today-twitterpp.html twitterpp
today-all:
	bin/krona --output html --filename today-all.html cities
full-csv:
	bin/krona  --filename all-results.csv csv
