require "csv"
require "time"

START_DATE = Time.parse("2020-06-01").to_date

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
  "Luik",
  "Mortsel",
  "Balen",
  "Heist-op-den-Berg",
  "Pelt"
].freeze

  # "Luik",
  # "Brussel",
  # "Anderlecht",
  # "Charleroi",
  # "Gent"

dates = START_DATE..Time.now.to_date
dates.each do |date|
  suffix = "%02d%02d" % [date.month, date.day]
  next if File.exist?("COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv")

  puts "-> Downloading #{suffix}"
  command = <<~SHELL
    curl -O "https://epistat.sciensano.be/Data/2020#{suffix}/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv"
SHELL
`#{command}`
end

data = {}
provinces = {}
citiesd = {}

cities = CITIES
Dir.glob("COVID19BE_CASES_MUNI_CUM*.csv").sort.each do |name|
  total_cases = 0
  date_part = name.split("_").last.split(".").first
  date = begin
           Time.parse(date_part)
         rescue ArgumentError
           nil
         end

  CSV.foreach(name, headers: true, encoding: "ISO-8859-1:UTF-8") do |row|
    city = row["TX_DESCR_NL"]
    cases = row["CASES"].to_i
    total_cases += cases
    province = row["TX_PROV_DESCR_NL"]
    provinces[province] ||=  {}
    provinces[province][date] ||= 0
    provinces[province][date] += cases


    citiesd[city] ||= {}
    citiesd[city][date] ||= 0
    citiesd[city][date] += cases
    next unless cities.include? city
    data[city] ||= []
    data[city] << [date, row["CASES"]]
  end
  data["Total"] ||= []
  data["Total"] << [date, total_cases]
rescue CSV::MalformedCSVError
  puts "#{name} kan het niet aan"
end

results = (CITIES + ["Total"]).inject({}) do |result, city|
  if arr = data[city]
    first, *rest = arr.sort_by(&:first).last(10)
    prev = first.last.to_i
    result[city] = rest.collect do |date, cases|
      cases = cases.to_i
      r = [date, cases - prev, cases]
      prev = cases
      r
    end.sort_by(&:first)
  end
  result
end
dates = results[CITIES.first].collect(&:first)
fd = dates.collect {|d| "%6s" % d.strftime("%a %d")}
header = "%20s |%s| %6s" % [ "City", fd.join("|"), "All Time"]
puts header
puts "-" * header.length
results.sort_by{|(i,j)| i}.each.with_index do |(city, data), index|
  fr = data.collect do |(date, delta, total)|
    if delta > 0
      "%6d" % delta
    elsif delta == 0
      "%6s" % ""
    else
      "%6s" % "*#{delta}*?"
    end
  end.join("|")
  if city == "Total"
    puts "-" * header.length
    city = "Les Belges"
  end
  puts ("%20s |%s| %6s" % [ city, fr, data.last[2]]) #.gsub("|", index.even? ? "|": " ")
end

prs = provinces.inject({}) do |result, (province, value)|
  arr = value.to_a
  first, *rest = arr.sort_by(&:first).last(10)
  prev = first.last.to_i
  result[province] = rest.collect do |date, cases|
    cases = cases.to_i
    r = [date, cases - prev, cases]
    prev = cases
    r
  end.sort_by(&:first)
  result
end

puts ""
puts ""

fd = dates.collect {|d| "%6s" % d.strftime("%a %d")}
header = "%20s |%s| %6s" % [ "Province", fd.join("|"), "Total"]
puts header
puts "-" * header.length
prs.sort_by{|(pr,data)| data.last[2]}.reverse_each do |province, data|
  fr = data.collect do |(date, delta, total)|
    if delta > 0
      "%6d" % delta
    elsif delta == 0
      "%6s" % ""
    else
      "%6s" % "*#{delta}*?"
    end
  end.join("|")
  name = province.gsub("Provincie ", "")
  puts "%20s |%s| %6s" % [ name, fr, data.last[2]]
end

crs = citiesd.inject([]) do |result, (city, value)|
  arr = value.to_a
  first, *rest = arr.sort_by(&:first).last(10)
  prev = first.last.to_i
  rs = rest.collect do |date, cases|
    cases = cases.to_i
    r = [date, cases - prev, cases]
    prev = cases
    r
  end.sort_by(&:first)
  result << [city, rs.last]
  result

end.sort_by{|(c,d,t)| d}.reverse

crs.first(25).each.with_index(1) do |(c,(date,delta,total)), i|
  s = "% 2d. %20s => % 3d" % [i,c,delta]
  puts s
rescue
  binding.irb
  exit
end
