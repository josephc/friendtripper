require 'rubygems'
require 'fastercsv'
require 'json'
require 'open-uri'


def build_address(addresscomponents)
  puts 
  address = String.new
  addresscomponents.each do |component|
    if component.to_s != ""
      if address == ""
        address = address + component
      else
        address = address + ", " + component
      end
    end
  end
  return address
end

filename = ARGV[0]

csv = FasterCSV.open( File.expand_path(filename), "r", :headers => true)
headers = csv.first.headers
csv.rewind
output_csv = FasterCSV.open("#{filename.gsub(/(\.csv)/,"")}_geocoded_result_#{Time.now.to_i}.csv", "w", :headers => headers, :write_headers => true)

csv.each do |row|
  successful_query = ""
  # name = row["POIName"].to_s.strip
  region = row["region"].to_s.strip
  city = row["city"].to_s.strip
  country = row["country"].to_s.strip

  addresscomponents = [city,region,country]
  address = build_address(addresscomponents)

  puts address

  
  # get the lat/lng
  fucked_count = 0
  second_address = false
  begin
    puts "Geocoding #{address}..."
    res = JSON.parse(open("http://maps.google.com/maps/api/geocode/json?address=#{URI.escape("#{address}")}&sensor=false").read)
    sleep 0.5 # throttle
    puts "STATUS: #{res['status']}"
    if res["status"] == "OK"
      g_lat = res["results"][0]["geometry"]["location"]["lat"].to_s
      g_long = res["results"][0]["geometry"]["location"]["lng"].to_s
    else
      raise # retry geocode
    end
  rescue
    fucked_count += 1
    if fucked_count > 2
      lat = ""
      lng = ""
      puts "Couldn't geocode #{address}..."
    else
      puts "Retrying #{address}..."
      retry
    end
  end
  new_row = row.to_hash
  new_row.merge!(
    "g_lat" => g_lat,
    "g_long" => g_long
  )
  output_csv << new_row
end
