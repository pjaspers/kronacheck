require 'erb'

module Krona
  class HTMLPrinter

    attr_accessor :data
    def initialize(data, title:, limit_to: [])
      @data = data
      @limit_to = limit_to
      @title = title
    end

    def description
      return "None! Good job everyone!" unless bad_ones.any?

      formatted = bad_ones.map{|c,dt| "*#{c}* (#{dt})"}
      if bad_ones.count > 1
        last = formatted.pop
        offenders = formatted.join(", ")
        "Herpakt yourself: #{[offenders, last].join(" and ")}"
      else
        "O #{formatted.first} toch"
      end
    end

    def bad_ones
      bad_ones = data.collect do |(item, data)|
        next if should_skip?(item)
        next if item == Parser::TOTAL_KEY
        _, delta, _ = data.detect {|(d,delta,_)| d == Date.today && delta > 0}
        [item, delta] if delta
      end.compact.sort_by(&:last).reverse
    end

    def twitter_card
      yesterday, today = (data.fetch(Parser::TOTAL_KEY, []).sort_by{|(i,j)| i}[-2..-1] || []).map{|_,dt,_| dt}
      card = {
        domain: "kronacheck.herokuapp.com",
        title: "#{@title}",
        description: description,
      }
      card.merge!(label1: "Yesterday", data1: yesterday) if yesterday
      card.merge!(label2: "Today", data2: today) if today
      card
    end

    def html
      template = File.read(File.join(Krona::TEMPLATE_DIR, 'result.html.erb'))
      ERB.new(template, trim_mode: ">").result(binding)
    end

    def dates
      data[data.keys.first].collect(&:first)
    end

    def should_skip?(item)
      return false if @limit_to.empty?
      return false if item == Parser::TOTAL_KEY

      !@limit_to.include?(item)
    end

    def headers
      ["City", *dates.collect {|d| d.strftime("%a %d%m") }, "All Time"].flatten
    end

    def rows
      @data.sort_by{|(i,j)| i}.collect.with_index do |(city, data), index|
        next if should_skip?(city)
        cells = data.collect do |(date, delta, total)|
          options = {length: 6}
          options.merge!(class: "today") if date == Date.today
          if delta > 0
            [delta, options]
          elsif delta == 0
            options[:class] = [options[:class], "no-cases"].compact.join(" ")
            ["", options]
          else
            ["*#{delta}*?", options]
          end
        end
        city = "Les Belges" if city == Parser::TOTAL_KEY
        [
          [city.gsub("Provincie ", ""), {}],
          *cells,
          [data.last[2], {}]
        ]
      end.compact
    end
  end
end
