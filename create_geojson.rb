require 'sqlite3'
require 'json'

def connect
  # create empty db
  @crimedb = SQLite3::Database.new "./crime_info.db"
  @geodb = SQLite3::Database.new "./geocoded.db"
end

def create
  connect
  
  ["Theft","Burglary","Rape","Murder","Auto Theft","Aggravated Assault","Robbery"].each do |offense_type|
	  p offense_type
	  geojson_data = Hash.new
	  geojson_data['type'] = 'FeatureCollection'
	  geojson_data['features'] = Array.new
	  
	  result_set = @crimedb.execute("select * from crime where offense_type='#{offense_type}'")
	  result_set.each do |incident|

		location_result = @geodb.execute("select * from locations where block_start = '#{incident[5]}' AND street_name = '#{incident[7]}' AND street_type = '#{incident[8]}'")
		location_result.each do |point|

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
	  end
	  File.open("./crime_points_#{offense_type.gsub(' ','_')}.json","w") do |f|
		f.write(JSON.pretty_generate(geojson_data))
	  end
  end
end

create
