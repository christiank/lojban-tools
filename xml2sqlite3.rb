require 'nokogiri'
require 'optparse'
require 'sqlite3'

class App
  MAXLEN = 40

  def initialize(argv=ARGV)
    @argv = argv
    @input_path = nil
    @quiet = false
  end

  def main
    parse_options
    setup
    add_words
    cleanup
    exit 0
  end

  def parse_options
    parser = OptionParser.new do |opts|
      opts.on("-i", "--input XML-FILE") { |i| @input_path = i }
      opts.on("-q", "--quiet") { @quiet = true }
    end
    parser.parse!(@argv)

    @input_path || complain("Expecting an input file")

    if !File.file?(@input_path)
      complain("Couldn't find input file #{@input_path}")
    end

    @output_path = @argv.shift || complain("Expecting an output file")
  end

  def complain(msg)
    $stderr.puts(msg)
    exit 1
  end

  def setup
    @input_f = File.open(@input_path)
    @xml = Nokogiri::XML(@input_f)
    @input_f.close

    @db = SQLite3::Database.new(@output_path)
    @db.execute('
      CREATE TABLE IF NOT EXISTS definitions (
        id INTEGER PRIMARY KEY,
        word TEXT,
        type TEXT,
        selmaho TEXT,
        definition TEXT,
        notes TEXT
      );
    ')
  end

  def add_words
    @counter = 0

    @xml.xpath("//valsi").each_with_index do |defn, i|
      cmd = %q[ 
        INSERT INTO DEFINITIONS (word, type, selmaho, definition, notes)
        VALUES (?, ?, ?, ?, ?);
      ]

      args = [
        defn.attribute("word").value,
        defn.attribute("type").value,
        defn.xpath("selmaho").inner_text,
        defn.xpath("definition").inner_text,
        defn.xpath("notes").inner_text,
      ]

      @db.execute(cmd, args)
      @counter += 1

      if not @quiet
        if i % 250 == 0
          msg = sprintf("zuktce... %s", defn.attribute("word").value)
          msglen = msg.length
          $stdout.printf("%s%s%s", msg, (" "*(MAXLEN-msglen)), ("\b"*MAXLEN))
        end
      end
    end
  end

  def cleanup
    @db.close
    if not @quiet
      $stdout.printf("%s%s", (" "*MAXLEN), ("\b"*MAXLEN))
      puts("mulno.")
      puts("#{@counter} valsi.")
    end
  end
end

#####

if __FILE__ == $0
  App.new.main
end
