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
                area text NOT NULL, \
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
                number_of_offenses text, \
                field11 text);");

    loadFiles
  end

  def loadFiles
    connect if !@conn
    @conn.prepare("insert_crime", "INSERT INTO crime (report_date, area, offense_date, hour, offense_type, beat, \
        premise, block_start, block_end, street_name, street_type, suffix, number_of_offenses, field11) \
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14);")
    Dir.glob('docs/**/*') do |f|
      CSV.foreach(f) do |row|
        next if row[5] == nil
        next if row[0] == "Date"

        p row

        file_name = f.split('/')[1].split('.')[0]
        block_start, block_end = row[5].split('-')

        @conn.exec_prepared("insert_crime", ["01-#{file_name[0..2]}-#{file_name[3..4]}", file_name[5..9],
        row[0], row[1], row[2], row[3], row[4], block_start, block_end, row[6], row[7], row[8], row[9], row[10]])
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

  get '/stats/historic/crimes/:area' do
    connect if !@conn
    events = Array.new

    # SQL read
    @conn.exec( "SELECT report_date, offense_type, count(*) FROM crime WHERE area='#{params[:area]}' GROUP BY report_date, offense_type" ) do |result|
      result.each do |row|
        p row
        events.push row
      end
    end
    return events.to_json
  end


end