require 'rubygems'
require 'json'
require 'uri'
require 'haversine.rb'

def get_lat_long(location)

  location_urlEncoded = URI.escape(location, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

  location_data = `curl -X GET 'http://nominatim.openstreetmap.org/search/#{location_urlEncoded}?format=json'`

  location_json = JSON.parse(location_data)

  if location_json.empty?
    puts "Failed on: #{location}"
    return south_pole = {
      :lat => -89.172096,
      :long => 0.087891
    }
  else 
    return location_point = {
      :lat => location_json[0]["lat"].to_f,
      :long => location_json[0]["lon"].to_f
    } 
  end
end

destination = ARGV[0]
max_distance = ARGV[1]
AUTH_KEY = "AAAAAAITEghMBAGvmZCMzOuqOrwZAZAnibtN4ANQHgZBtW9Ba3Sk0RSfoeOFXtLtDbeoBSZAIZAaPHydOjCwpLeRvv3jV3Vo4MEl6NnTCbzZCQZDZD"
friends_to_visit = []
friend_data = []
# # track efficiency improvements
# api_calls_saved = 0
places = {}
retrys = 0
friends_with_location = 0

destination_point = get_lat_long(destination)

friends = `curl -X GET 'https://graph.facebook.com/me/friends?access_token=#{AUTH_KEY}'`

parsed_friends = JSON.parse(friends)

friends_data = parsed_friends["data"]

friends_array = friends_data.map { |friend| "{\"method\": \"GET\", \"relative_url\": \"#{friend["id"]}\"}" }

i = 0

while !friends_array.empty?

  fifty_friends = "#{friends_array.shift(50).join(",")}"

  friend_data << `curl -F 'access_token=#{AUTH_KEY}' -F 'batch=[ #{fifty_friends} ]' 'https://graph.facebook.com'`
  
  # if friend_data[i] == ""
  #   puts "curl error while requesting names"
  #   retrys += 1
  #   if retrys > 3
  #     retrys = 0
  #     next
  #   else
  #     redo
  #   end
  # end
  # 
  # i += 1
  
end

friend_data.each do |data|
  JSON.parse(data).each do |friend|
    if JSON.parse(friend["body"])["location"].to_s != ""
      friend = JSON.parse(friend["body"])
      # puts "#{friend["name"]}, #{friend["location"]["name"]}"

      friend_location_name = friend["location"]["name"]


      if friend_location_name.to_s != ""

        if  places[friend_location_name].to_s == ""

          friend_location_point = get_lat_long(friend_location_name)

          friend_distance = haversine_distance(friend_location_point[:lat],friend_location_point[:long],destination_point[:lat],destination_point[:long])

          places[friend_location_name] = {
            :point => friend_location_point,
            :distance => friend_distance
          }
        else
          # api_calls_saved += 1          
          friend_distance = places[friend_location_name][:distance]
        end

        if friend_distance < max_distance.to_f
          # p "#{friend["name"]}, #{friend_location_name}"
          friends_to_visit << "#{friend["name"]}, #{friend_location_name}"
        end
        friends_with_location += 1
      end
    end
  end
end


puts "#{friends_with_location} out of #{friends_data.length} of your friends (#{(friends_with_location.to_f/friends_data.length.to_f*100).to_int}%) have location info."
# puts "You saved #{api_calls_saved} api calls by caching locations!"
puts "You might consider visiting the following friends, while you are in #{destination}:\n#{friends_to_visit.join("\n")}"
