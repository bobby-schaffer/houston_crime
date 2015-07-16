require 'csv'
require 'sqlite3'
# require 'Spreadsheet'
require 'net/http'
require 'json'

def connect
  # create empty db
  @db = SQLite3::Database.new "./crime_info.db"
  @geodb = SQLite3::Database.new "./geocoded.db"
end

def bootstrap
  connect if !@db

  # Date,Hour,Offense Type,Beat,Premise,Block Range,Street Name,Type,Suffix,# Of Offenses,Field11
  @db.execute("DROP TABLE IF EXISTS crime;")
  @db.execute("CREATE TABLE crime ( \
              report_date date NOT NULL, \
              offense_date date, \
              hour smallint, \
              offense_type text, \
              beat text, \
              block_start text, \
              block_end text, \
              street_name text, \
              street_type text, \
              suffix text, \
              number_of_offenses smallint, \
              lat text, long text);");

  loadFiles
end

def loadFiles
  connect if !@db
  Dir.glob('docs/**/*') do |f|
    doc = Spreadsheet.open (f)
    sheet = doc.worksheet 0
    sheet.each 1 do |row|
      next if row[5] == nil
      next if row[0] == "Date"

      row[1] = 99 if row[1] == ""
      file_name = f.split('/')[1].split('.')[0]
      block_start, block_end = row[5].split('-')

      row[9] = 1 if row[9] == ""

      @db.execute("INSERT INTO crime (report_date, offense_date, hour, offense_type, beat, \
          block_start, block_end, street_name, street_type, suffix, number_of_offenses) \
          values ('01-#{file_name[0..2]}-#{file_name[3..4]}', '#{row[0]}', #{row[1]}, '#{row[2]}', \
          '#{row[3]}', '#{block_start}', '#{block_end}', '#{row[6]}', '#{row[7]}', '#{row[8]}', #{row[9]});")
    end
  end
end

def geocode
  connect
  limit = 0
  result_set = @db.execute("select block_start, street_name, street_type from (select distinct * from crime)")
  result_set.each do |result|
    next if result[0] == "UNK"

    is_done = @geodb.execute("select * from locations where block_start='#{result[0]}' and street_name='#{result[1]}' and street_type='#{result[2]}'")
    next if is_done.length > 0

    # http://maps.googleapis.com/maps/api/geocode/json?address=5000+Briarbend+Drive,+Houston,+TX&sensor=true_or_false
    # "/maps/api/geocode/json?address=2300+NAVIGATION+-,+Houston,+TX&sensor=true_or_false"

    street_type = ""
    street_type = "+#{result[2]}" if result[2] != "-"

    query = URI("http://maps.googleapis.com/maps/api/geocode/json?address=#{result[0]}+#{result[1].gsub(' ','+')}#{street_type},+Houston,+TX&sensor=true_or_false")
    p query
    geodata = JSON.parse(Net::HTTP.get(query))

    limit += 1

    lat = geodata['results'][0]['geometry']['location']['lat']
    long = geodata['results'][0]['geometry']['location']['lng']

    print "#{result[0]} #{result[1]} #{lat} #{long}\n"

    @geodb.execute("insert into locations (block_start, street_name, street_type, lat, long) values ('#{result[0]}','#{result[1]}','#{result[2]}','#{lat}','#{long}')")
    break if limit == 2450
    sleep 0.21
  end
end

geocode
