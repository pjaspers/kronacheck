require "net/http"

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
      last_date_found = Time.parse(date_part).to_date

      # Check for at least 3 days in ahead, because sometimes
      # Sciensano adds gaps to the data. To relieve some of the burden
      # of the hospitals for entering this data. Why they don't focus
      # on making entering the data really easy? ,,shrug
      [1,2,3].any? do |i|
        puts "Checking #{last_date_found + i}..."
        exists_remotely?(url_for(date: last_date_found + i))
      end
    end

    def exists_remotely?(url)
      command = <<~SHELL
      curl -s -o /dev/null -w "%{http_code}"  "#{url}"
      SHELL
      result = `#{command}`.strip
      result == "200"
    end

    def suffix_for(date:)
      "%02d%02d" % [date.month, date.day]
    end

    def url_for(date:)
      suffix = suffix_for(date: date)
      year = date.year
      "https://epistat.sciensano.be/Data/#{year}#{suffix}/COVID19BE_CASES_MUNI_CUM_#{year}#{suffix}.csv"
    end

    def has_remote_file?(date:)
      has_remote_file_curl?(date: date)
    end

    def has_remote_file_curl?(date:)
      url = url_for(date: date)
      code = `curl -o /dev/null --head #{url} -s -w "%{http_code}"`.strip
      if code == "200"
        true
      else
        puts "-> Skipping #{date} because it maybe doesn't have data? #{code}"
        false
      end
    end

    def has_remote_file_nethttp?(date:)
      url = url_for(date: date)
      uri = URI.parse(url)
      request = Net::HTTP::Head.new(uri)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 0.1, open_timeout: 0.1) do |http|
        http.request(request)
      end

      if response["content-length"].to_f > 30000
        true
      else
        puts "-> Skipping #{date} because it doesn't seem to have content"
        false
      end
    rescue Net::OpenTimeout
      # Well this is weird, if you run this request with a `curl
      # --head` it will return the 404, but for some reason net/http
      # will throw an open timeout.
      #
      puts "-> Skipping #{date} because it maybe doesn't have data? #{code}"
      false
    end


    def call
      dates.each do |date|
        suffix = suffix_for(date: date)
        year = date.year
        next if has_valid_csv?(path: "data/COVID19BE_CASES_MUNI_CUM_#{year}#{suffix}.csv")
        next unless has_remote_file?(date: date)

        puts "-> Downloading #{suffix}"
        command = <<~SHELL
    curl --fail -o "data/COVID19BE_CASES_MUNI_CUM_#{year}#{suffix}.csv" "#{url_for(date: date)}"
SHELL
        `#{command}`
      end
    end

    def has_valid_csv?(path:)
      File.exist?(path)
    end
  end
end
