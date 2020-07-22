build: today-limited today-all full-json

today-limited:
	ruby other_thing.rb --write-html
today-all:
	ruby other_thing.rb --write-html --all
full-json:
	(LAST_N=1000 ruby other_thing.rb --all)
