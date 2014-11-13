# need to require json since redis the data file is written in json
# json is a convenient way to enter key value pairs for both people and machines
# redis stores data in k => v pairs
require 'json'
require 'redis'
require 'pry'

#instantiating a new instance redis by calling the ruby Module Redis
$redis = Redis.new(url: ENV["REDISTOGO_URL"])

# best practice to delete old data when seeding
$redis.flushdb

# telling redis to set/save koopas with an index starting at 0
$redis.set("koopa:index", 0)

# optional
puts "Importing data..."

# holding the parsed json file data opened in the file stream command File.read
db_koopa_data = JSON.parse(File.read("koopa_data_file.json"))


# parsed json data array ready for ruby to iterate over each instance of koopa 
db_koopa_data["koopas"].each do |koopa|

	# index variable will hold an indexed/orederd list of koopas
	index = $redis.incr("koopa:index")

	# iterated koopa instance assigned an index value
	koopa[:id] = index

	# redis saves an indexed array of koopas as json objects
	$redis.set("koopas:#{index}", koopa.to_json)
	#binding.pry
end

# appears in terminal when seeding through $ ruby seeds.rb
puts "The following records #{$redis.keys.count} were imported"