require_relative "krona/fetcher"
require_relative "krona/parser"
require_relative "krona/shell_printer"

module Krona
  # Earliest date I can find on Sciensano site
  #
  # This is used by `fetcher.rb` to start fetching CSV's from that day
  # onwards. However, the first 8 or so fail with a 404, ,,shrug
  START_DATE = Time.parse("2020-03-25").to_date
end

CITIES = [
  "Aartselaar",
  "Leuven",
  "Hamont-Achel",
  "Kortrijk",
  "De Panne",
  "Herentals",
  "Antwerpen",
  "Peer",
  "Edegem",
  "Kontich",
  "Mortsel",
  "Balen",
  "Heist-op-den-Berg",
  "Pelt",
  "Veurne",
  "Kampenhout",
  "Olen",
  "Boom"
].freeze

parser = Krona::Parser.new(directory: "data")

puts Krona::ShellPrinter.new(parser.cities, title: "Cities", limit_to: CITIES).overview

puts Krona::ShellPrinter.new(parser.provinces, title: "Provinces").overview

# puts Krona::ShellPrinter.new(parser.cities, title: "Provinces").worst_ones
