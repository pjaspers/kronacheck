module Krona
  class Fetcher
    def initialize(start_date)
      @start_date = start_date
    end

    def dates
      @start_date..Time.now.to_date
    end

    def new_data?
      last_file = Dir.glob("data/COVID19BE_CASES_MUNI_CUM_*").max
      date_part = last_file.split("_").last.split(".").first
      next_day = Time.parse(date_part).to_date + 1
      command = <<~SHELL
      curl -s -o /dev/null -w "%{http_code}"  "#{url_for(date: next_day)}"
      SHELL
      result = `#{command}`.strip
      result == "200"
    end

    def suffix_for(date:)
      "%02d%02d" % [date.month, date.day]
    end

    def url_for(date:)
      suffix = suffix_for(date: date)
      "https://epistat.sciensano.be/Data/2020#{suffix}/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv"
    end

    def call
      dates.each do |date|
        suffix = suffix_for(date: date)
        next if File.exist?("data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv")

        puts "-> Downloading #{suffix}"
        command = <<~SHELL
    curl --fail -o "data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv" "#{url_for(date: date)}"
SHELL
        `#{command}`
      end
    end
  end
end
