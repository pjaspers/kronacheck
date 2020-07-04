# Checks the krona

There's a cronjob that runs the following every hour:

`ruby other_thing.rb --write-html && ruby other_thing.rb --write-html --all`

This will pull in new CSV's, and spit out new HTML into the results directory and update the today.html, which is served by Rack.

It's very stupid, but it works.
