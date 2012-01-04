require 'rubygems'
require 'haversine.rb'
require 'fastercsv'

headers = ["country","country_code","region","city","id","osm_lat","osm_long","g_lat","g_long"] 
new_headers = headers + ["distance"]

FasterCSV.open("geocoded_comparison.csv", 'w', :write_headers=>true, :headers=>new_headers) do |compare|
	FasterCSV.foreach("google_check.csv",:headers=>true) do |row|
	  coordinates = [row["osm_lat"].to_f,row["osm_long"].to_f,row["g_lat"].to_f,row["g_long"].to_f]
	  coordinates.each_with_index do |coord,i|
	    if coord.to_s == ""
	      coordinates[i] = 0
      end
	  end
		distance = haversine_distance(*coordinates)
		compare << headers.map { |h| row[h] } + [distance]
	end
end