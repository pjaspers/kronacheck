module Krona
  class ShellPrinter

    attr_accessor :data
    def initialize(data, title:, limit_to: [])
      @data = data
      @limit_to = limit_to
      @title = title
    end

    def table(title, &block)
      io = StringIO.new
      io.puts("# #{title}")
      io.puts("")
      block.call(io)
      io.puts("")
      io.rewind
      io.read
    end

    def list(options = {}, &block)
      io = StringIO.new
      io.puts("")
      block.call(io)
      io.puts("")
      io.rewind
      io.read
    end

    def list_item(s, options = {})
      s
    end

    def cell(s, options = {})
      "%#{options.fetch(:length, "")}s"  % s
    end

    def hcell(s, options = {})
      "%#{options.fetch(:length, "")}s" % s
    end

    def row(*cols)
      cols.join("|")
    end

    def joiner(j)
      j.join("|")
    end

    def row_divider(length)
      row("-" * length)
    end

    def dates
      data[data.keys.first].collect(&:first)
    end

    def should_skip?(item)
      return false if @limit_to.empty?
      return false if item == Parser::TOTAL_KEY

      !@limit_to.include?(item)
    end

    def overview
      fd = dates.collect {|d| hcell(d.strftime("%a %d"), length: 6)}
      header = row(hcell(@title, length: 20), joiner(fd), hcell("All Time", length: 6))
      r = table(@title) do |io|
        io.puts header
        io.puts row_divider(header.length)
        @data.sort_by{|(i,j)| i}.each.with_index do |(city, data), index|
          next if should_skip?(city)
          fr = data.collect do |(date, delta, total)|
            options = {length: 6}
            options.merge!(class: "today") if date == Date.today
            if delta > 0
              cell(delta, options)
            elsif delta == 0
              options[:class] = [options[:class], "no-cases"].compact.join(" ")
              cell("", options)
            else
              cell("*#{delta}*?", options)
            end
          end
          fr = joiner(fr)
          if city == Parser::TOTAL_KEY
            io.puts row_divider(header.length)
            city = "Les Belges"
          end
          io.puts row(cell(city.gsub("Provincie ", ""), length: 20), fr, cell(data.last[2], length: 6))
        end
      end
      puts r
    end

    def worst_ones(n: 10)
      list do |io|
        items = @data.sort_by{|(c,d,t)| d}.reverse_each.first(n)
        items.each.with_index(1) do |(c, data), i|
          date,delta,total = data
          binding.irb
          s = "% 2d. %20s => % 3d" % [i,c,delta]
          io.puts list_item.(s)
        end
      end
    end
  end
end
