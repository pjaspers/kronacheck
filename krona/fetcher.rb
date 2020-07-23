module Krona
  class Fetcher
    def initialize(start_date)
      @start_date = start_date
    end

    def dates
      @start_date..Time.now.to_date
    end

    def call
      dates.each do |date|
        suffix = "%02d%02d" % [date.month, date.day]
        next if File.exist?("data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv")

        puts "-> Downloading #{suffix}"
        command = <<~SHELL
    curl --fail -o "data/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv" "https://epistat.sciensano.be/Data/2020#{suffix}/COVID19BE_CASES_MUNI_CUM_2020#{suffix}.csv"
SHELL
        `#{command}`
      end
    end
  end
end
