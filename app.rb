require 'bundler'
Bundler.require

require 'csv'

class HoustonCrime < Sinatra::Base

  def connect
    @conn = PG.connect(
        :dbname => ENV['DB_NAME'],
        :user => ENV['DB_USER'],
        :password => ENV['DB_PASSWORD'],
        :host => ENV['DB_HOST'],
        :port => ENV['DB_PORT']
    )
  end

  def bootstrap
    connect if !@conn

    # Date,Hour,Offense Type,Beat,Premise,Block Range,Street Name,Type,Suffix,# Of Offenses,Field11
    @conn.exec("DROP TABLE IF EXISTS crime;")
    @conn.exec("CREATE TABLE crime ( \
                report_date date NOT NULL, \
                offense_date date, \
                hour smallint, \
                offense_type text, \
                beat text, \
                premise text, \
                block_start text, \
                block_end text, \
                street_name text, \
                street_type text, \
                suffix text, \
                number_of_offenses text);");

    loadFiles
  end

  def loadFiles
    connect if !@conn
    @conn.prepare("insert_crime", "INSERT INTO crime (report_date, offense_date, hour, offense_type, beat, \
        premise, block_start, block_end, street_name, street_type, suffix, number_of_offenses) \
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);")
    Dir.glob('docs/**/*') do |f|
      doc = Spreadsheet.open (f)
      sheet = doc.worksheet 0
      sheet.each 1 do |row|
        next if row[5] == nil
        next if row[0] == "Date"

        file_name = f.split('/')[1].split('.')[0]
        block_start, block_end = row[5].split('-')

        @conn.exec_prepared("insert_crime", ["01-#{file_name[0..2]}-#{file_name[3..4]}",
        row[0], row[1], row[2], row[3], row[4], block_start, block_end, row[6], row[7], row[8], row[9]])
      end
    end
  end

  get '/' do
    redirect '/index.html'
  end

  get '/bootstrap' do
    bootstrap
    return 'Success'
  end

  get '/loadfiles' do
    loadFiles
    return 'Success'
  end

  get '/stats/historic/crimes/:beat' do
    connect if !@conn
    data = Hash.new

    # get all crime types in db
    crime_types = Array.new
    @conn.exec('SELECT offense_type FROM crime GROUP BY offense_type ORDER BY offense_type') do |result|
      crime_types = result.values
    end

    p crime_types

    # get stats for each type
    crime_info = Hash.new
    crime_types.each_index { |index|
      @conn.exec( "SELECT report_date, count(*) FROM crime WHERE beat='#{params[:beat]}' AND offense_type='#{crime_types[index][0]}' GROUP BY report_date ORDER BY report_date" ) do |result|
        result.each do |row|
          crime_info[row["report_date"]] = Array.new if crime_info[row["report_date"]] == nil
          crime_info[row["report_date"]][index] = row["count"]
        end
      end
    }

    data_value = Array.new
    crime_info.each_pair {|date, values|
      newVal = Hash.new
      newVal['x'] = date
      newVal['y'] = values
      data_value.push(newVal)
    }

    data = {
        'series'=> crime_types,
        'data' => data_value
    }

    return data.to_json
  end


end