require_relative "krona/fetcher"
require_relative "krona/parser"
require_relative "krona/shell_printer"
require_relative "krona/html_printer"
require_relative "krona/csv_printer"

module Krona
  # Earliest date I can find on Sciensano site
  #
  # This is used by `fetcher.rb` to start fetching CSV's from that day
  # onwards. However, the first 8 or so fail with a 404, ,,shrug
  START_DATE = Time.parse("2020-03-25").to_date

  TEMPLATE_DIR = "templates"
end
