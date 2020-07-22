require "csv"
require "time"

# Yes, an external dependency, I know, I feel you. But that name, who
# could resist using this? Not me.
require "charlock_holmes"

# Earliest date I can find on Sciensano site
START_DATE = Time.parse("2020-03-25").to_date

SHOW_LAST_N = ENV.fetch("LAST_N", 10).to_i

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

TOTAL_KEY= "’’’TOTAL"

  # "Luik",
  # "Brussel",
  # "Anderlecht",
  # "Charleroi",
  # "Gent"
@limit_cities = true
table= ->(title, &block) do
  io = StringIO.new
  io.puts("# #{title}")
  io.puts("")
  block.call(io)
  io.puts("")
  io.rewind
  puts io.read
end
list = ->(options = {}, &block) do
  io = StringIO.new
  io.puts("")
  block.call(io)
  io.puts("")
  io.rewind
  puts io.read
end
list_item = ->(s, options = {}) { s}
cell = ->(s, options = {}) { "%#{options.fetch(:length, "")}s"  % s}
hcell = ->(s, options = {}) { "%#{options.fetch(:length, "")}s" % s}
row = ->(*cols) { cols.join("|") }
joiner = ->(j) { j.join("|") }
row_divider = ->(length) { row.("-" * length)}

if ARGV.include?("--write-html")
  @write_html = true
  tag = ->(name, content, options = {}) do
    name = String(name)
    start = name
    css_classes = (Array(options[:class]) || []).compact
    start = "#{name} class='#{css_classes.join(" ")}'" if css_classes.any?
    <<~HTML
<#{start}>
  #{content}
</#{name}>
HTML
  end
  table= ->(title, &block) do
    io = StringIO.new
    io.puts("<h2>#{title}</h2>")
    io.puts("<table>")
    block.call(io)
    io.puts("</table>")
    io.rewind
    io.read
  end
  list = ->(options = {}, &block) do
    io = StringIO.new
    io.puts "<ul>"
    block.call(io)
    io.puts("</ul>")
    io.rewind
    io.read
  end
  list_item = ->(s, options = {}) { tag.(:li, s, options)}

  cell = ->(s, options = {}) { tag.(:td, s, options) }
  hcell = ->(s, options = {}) { tag.(:th, s, options) }
  row = ->(*cols) { tag.(:tr, cols.join(" ")) }
  row_divider = ->(length) { row.([]) }
  joiner = ->(j) { j }
end

if ARGV.include?("--all")
  @limit_cities = false
end

dates = START_DATE..Time.now.to_date
dates.each do |date|
  suffix = "%02d%02d" % [date.month, date.day]
  next if File.exist?("data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv")

  puts "-> Downloading #{suffix}"
  command = <<~SHELL
    curl --fail -o "data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv" "https://epistat.sciensano.be/Data/2020#{suffix}/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv"
SHELL
`#{command}`
end

data = {}
provinces = {}
citiesd = {}

cities = CITIES
Dir.glob("data/COVID19BE_CASES_MUNI_CUM*.csv").sort.each do |name|
  total_cases = 0
  date_part = name.split("_").last.split(".").first
  date = begin
           Time.parse(date_part)
         rescue ArgumentError
           nil
         end.to_date

  detection = CharlockHolmes::EncodingDetector.detect(File.read(name))

  CSV.foreach(name, headers: true, encoding: "#{detection[:encoding]}:UTF-8") do |row|
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
    should_skip = @limit_cities && !cities.include?(city)
    next if should_skip
    data[city] ||= []
    data[city] << [date, row["CASES"]]
  end
  data[TOTAL_KEY] ||= []
  data[TOTAL_KEY] << [date, total_cases]
rescue CSV::MalformedCSVError
  puts "#{name} kan het niet aan"
end

results = (data.keys + [TOTAL_KEY]).inject({}) do |result, city|
  if arr = data[city]
    first, *rest = arr.sort_by(&:first).last(SHOW_LAST_N)
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
fd = dates.collect {|d| hcell.(d.strftime("%a %d"), length: 6)}
header = row.(hcell.("City", length: 20), joiner.(fd), hcell.("All Time", length: 6))
r = table.("Cities") do |io|
  io.puts header
  io.puts row_divider.(header.length)
  results.sort_by{|(i,j)| i}.each.with_index do |(city, data), index|
    fr = data.collect do |(date, delta, total)|
      options = {length: 6}
      options.merge!(class: "today") if date == Date.today
      if delta > 0
        cell.(delta, options)
      elsif delta == 0
        options[:class] = [options[:class], "no-cases"].compact.join(" ")
        cell.("", options)
      else
        cell.("*#{delta}*?", options)
      end
    end
    fr = joiner.(fr)
    if city == TOTAL_KEY
      io.puts row_divider.(header.length)
      city = "Les Belges"
    end
    io.puts row.(cell.(city, length: 20), fr, cell.(data.last[2], length: 6)) #.gsub("|", index.even? ? "|": " ")
  end
end

CSV.open("results.csv", "wb") do |csv|
  csv << %w(city date delta total)
  results.each do |city, data|
    next if city == TOTAL_KEY
    data.each do |(date, delta, total)|
      csv << [city, date.to_s, delta, total]
    end
  end
end

bad_ones = results.map do |(city, data)|
  next if city == TOTAL_KEY
  _, delta, _ = data.detect {|(d,delta,_)| d == Date.today && delta > 0}
  [city, delta] if delta
end.compact.sort_by(&:last).reverse

yesterday, today = results[TOTAL_KEY].sort_by{|(i,j)| i}[-2..-1].map{|_,dt,_| dt}
puts "Yesterday: #{yesterday} Today: #{today}"
description = if bad_ones.any?
                formatted = bad_ones.map{|c,dt| "*#{c}* (#{dt})"}
                if bad_ones.count > 1
                  last = formatted.pop
                  offenders = formatted.join(", ")
                  "Fucking #{[offenders, last].join(" and ")}"
                else
                  "Fucking #{formatted.first}"
                end
              else
                "None! Good job everyone!"
              end
puts description
if @write_html
  basename = ["result"]
  basename << "all" unless @limit_cities
  basename << "%02d%02d" % [Date.today.month, Date.today.day]
  filename = "#{basename.join("-")}.html"
  title = "Krona on #{Date.today.strftime("%d-%m-%Y")}"
  twitter_card = {
    domain: "kronacheck.herokuapp.com",
    title: "#{title}",
    description: description,
    label1: "Yesterday",
    data1: yesterday,
    label2: "Today",
    data2: today
  }.map {|key, val| "<meta name='twitter:#{key}' value='#{val}' />" }.join("\n")

  html = <<~HTML
<html>
  <head>
    <title>#{title}</title>
    #{twitter_card}
    <meta name="viewport" content="user-scalable=no, initial-scale=1, width=device-width">
    <link rel="stylesheet" href="a-maxvoltar-special.css">
    <!-- Generated on #{Time.now.to_s} -->
  </head>
  <body>
    #{r}
  </body>
</html>
HTML
  File.open(File.join("results", filename), "w") {|f| f.puts html }
  puts "Wrote #{filename}"
  if File.exist?(File.join("results", filename))
    require "fileutils"
    basename = ["today"]
    basename << "all" unless @limit_cities
    new_filename = "#{basename.join("-")}.html"
    FileUtils.cp(File.join("results", filename), new_filename)
  end
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

fd = dates.collect {|d| cell.(d.strftime("%a %d"), length: 6)}
header = row.(hcell.("Province", length: 20), joiner.(fd), hcell.("Total", length: 6))
r = table.("Provinces") do |io|
  io.puts header
  io.puts row_divider.(header.length)
  prs.sort_by{|(pr,data)| data.last[2]}.reverse_each do |province, data|
    fr = data.collect do |(date, delta, total)|
      options = {length: 6}

      if delta > 0
        cell.(delta, options)
      elsif delta == 0
        cell.("", options)
      else
        cell.("*#{delta}*?", options)
      end
    end
    fr = joiner.(fr)
    name = province.gsub("Provincie ", "")
    io.puts row.(cell.(name, length: 20), fr, cell.(data.last[2], length: 6))
  end
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

list.() do |io|
  crs.first(10).each.with_index(1) do |(c,(date,delta,total)), i|
    s = "% 2d. %20s => % 3d" % [i,c,delta]
    io.puts list_item.(s)
  end
end
