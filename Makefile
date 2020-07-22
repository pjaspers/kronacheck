build: today-limited today-all full-json

today-limited:
	bundle exec ruby other_thing.rb --write-html
today-all:
	bundle exec ruby other_thing.rb --write-html --all
full-json:
	(LAST_N=1000 bundle exec ruby other_thing.rb --all)
