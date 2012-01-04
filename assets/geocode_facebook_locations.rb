require 'rubygems'
require 'json'
require 'uri'
require 'haversine.rb'
require 'fastercsv'

def get_lat_long(location)

  location_urlEncoded = URI.escape(location, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

  location_data = `curl -X GET 'http://nominatim.openstreetmap.org/search/#{location_urlEncoded}?format=json'`

  location_json = JSON.parse(location_data)

  if location_json.empty?
    puts "Failed on: #{location}"
    return south_pole = {
      :lat => "error",
      :long => "error"
    }
  else 
    return location_point = {
      :lat => location_json[0]["lat"].to_f,
      :long => location_json[0]["lon"].to_f
    } 
  end
end

headers = ["country", "country_code", "region", "city", "id"]
new_headers = ["country", "country_code", "region", "city", "id", "lat","long"]

FasterCSV.open("all_cities_utf8v2_GeoCoded_1.csv", 'w', :headers => new_headers, :write_headers => true) do |new_location|
  FasterCSV.foreach("all_cities_utf8v2_1.csv", :headers => true) do |location|
    if location["region"].to_s.strip == "" or location["country"] == "United Kingdom"
      destination = location["city"].to_s.strip + ", " + location["country"].to_s.strip
    elsif location["country"] == "United States"
      destination = location["city"].to_s.strip + ", " + location["region"].to_s.strip
    else
      destination = location["city"].to_s.strip + ", " + location["region"].to_s.strip + ", "+ location["country"].to_s.strip
    end
    
    # p destination
    
    destination_point = get_lat_long(destination)
    new_location << headers.map { |h| location[h] } + [destination_point[:lat],destination_point[:long]]
  end
end