require "csv"
require "time"
require "date"
require "net/http"
require "uri"

CITIES = [
  "Leuven",
  "Hamont-Achel",
  "Kortrijk",
  "De Panne",
  "Herentals",
  "Antwerpen",
  "Balen"
].freeze

URL = "https://epistat.sciensano.be/Data/COVID19BE_CASES_MUNI.csv"
FILENAME = "COVID19BE_CASES_MUNI_#{Time.now.strftime("%y%m%d")}.csv"

def download(url:, to:)
  return if File.exist?(to)

  uri = URI.parse(url)
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    head_req = Net::HTTP::Head.new(uri)
    response = http.request(head_req)
    total_size = response['content-length'].to_i

    get_req = Net::HTTP::Get.new(uri)
    progress = 0
    http.request(get_req) do |response|
      File.open(to, 'w') do |f|
        response.read_body do |chunk|
          f.write chunk
          progress += chunk.length
          yield(progress, total_size) if block_given?
        end
      end
    end
  end
end

def last_seen_date(csv:)
  max_date_seen = nil
  CSV.foreach(csv, headers: true, encoding: "ISO-8859-1:UTF-8") do |row|

    date = begin
             Time.parse(row["DATE"])
           rescue ArgumentError
             nil
           end
    next unless date
    max_date_seen ||= date
    max_date_seen = date if date > max_date_seen
  end
  max_date_seen
end

# { city_a: [[date, cases], ...], city_b: [[date, cases], ...] }
def parse(csv:, cities:, end_date:)
  data = {}
  CSV.foreach(csv, headers: true, encoding: "ISO-8859-1:UTF-8") do |row|
    city = row["TX_DESCR_NL"]
    next unless cities.include? city
    date = begin
             Time.parse(row["DATE"])
           rescue ArgumentError
             nil
           end
    next unless date
    next unless date > (end_date.to_time - 10*24*60*60)
    data[city] ||= []
    data[city] << [date, row["CASES"]]
  end
  data
end

def output(parsed_data:, end_date:)
  puts "In the 10 days before #{end_date}"
  CITIES.each do |city|
    puts city
    if arr = parsed_data[city]
      arr.sort_by(&:first).reverse_each do |date, cases|
        puts "  #{date} => #{cases}"
      end
    else
      puts "  None! Good job everyone!"
    end
  end
end

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-f", "--filename=FILENAME", "Run with filename") do |f|
    options[:filename] = f
  end
end.parse!

filename = options[:filename] || FILENAME
unless options[:filename]
  download(url: URL, to: filename)
end
max_date = last_seen_date(csv: filename)
parsed_data = parse(csv: filename, cities: CITIES, end_date: max_date)
output(parsed_data: parsed_data, end_date: max_date)
