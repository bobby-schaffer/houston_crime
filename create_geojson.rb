require 'sqlite3'
require 'json'

def connect
  # create empty db
  # @db = SQLite3::Database.new "./crime_info.db"
  @geodb = SQLite3::Database.new "./geocoded.db"
end

def create
  connect
  geojson_data = Hash.new
  geojson_data['type'] = 'FeatureCollection'
  geojson_data['features'] = Array.new

  result_set = @geodb.execute("select * from locations")
  result_set.each do |point|

    street_type = point[2] != "-" ? point[2] : ""

    feature = Hash.new
    feature['type'] = 'Feature'
    feature['geometry'] = Hash.new
    feature['geometry']['type'] = 'Point'
    feature['geometry']['coordinates'] = Array.new
    feature['geometry']['coordinates'] = point[4].to_f, point[3].to_f
    feature['properties'] = Hash.new
    feature['properties']['address'] = "#{point[0]} #{point[1]} #{street_type}"
    feature['properties']['mag'] = "3"

    geojson_data['features'].push(feature)
  end
  File.open("./crime_points.json","w") do |f|
    f.write(JSON.pretty_generate(geojson_data))
  end
end

create
