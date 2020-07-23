require 'csv'

module Krona
  class CSVPrinter

    attr_accessor :data
    def initialize(data, title:, limit_to: [])
      @data = data
      @limit_to = limit_to
      @title = title
    end

    def csv
      CSV.generate do |csv|
        csv << %w(city date delta total)
        data.each do |city, data|
          next if city == Parser::TOTAL_KEY
          data.each do |(date, delta, total)|
            csv << [city, date.to_s, delta, total]
          end
        end
      end
    end
  end
end
