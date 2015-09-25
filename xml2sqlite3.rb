require 'nokogiri'
require 'sqlite3'

f = File.open("English-lojban.xml")
xml = Nokogiri::XML(f)
f.close

db = SQLite3::Database.new("./english-lojban.sqlite3")
db.execute('
  CREATE TABLE IF NOT EXISTS definitions (
    id INTEGER PRIMARY KEY,
    word TEXT,
    type TEXT,
    selmaho TEXT,
    definition TEXT,
    notes TEXT
  );
')

MAXLEN = 40

xml.xpath("//valsi").each_with_index do |defn, i|
  db.execute(
    %q[
      INSERT INTO DEFINITIONS (word, type, selmaho, definition, notes)
      VALUES (?, ?, ?, ?, ?);
    ],
    [
      defn.attribute("word").value,
      defn.attribute("type").value,
      defn.xpath("selmaho").inner_text,
      defn.xpath("definition").inner_text,
      defn.xpath("notes").inner_text,
    ]
  )

  if i % 250 == 0
    msg = sprintf("zuktce... %s", defn.attribute("word").value)
    msglen = msg.length
    $stdout.printf("%s%s%s", msg, (" "*(MAXLEN-msglen)), ("\b"*MAXLEN))
  end
end

$stdout.printf("%s%s", (" "*MAXLEN), ("\b"*MAXLEN))
puts("mulno.")
db.close
