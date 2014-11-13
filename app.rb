# require the following gems
require 'sinatra/base'
require 'redis'
require 'json'

# inheriting from Sinata Base which runs on a Rack engine
class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  # logging messages to terminal # enabling the override for edit and delete
  configure do
    enable :logging
    enable :method_override
    enable :sessions
  end


  ########################
    # DB Configuration
  ########################

 $redis = Redis.new(:url => ENV["REDISTOGO_URL"])



  # these bedfores and afters will print in terminal to display params
  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end



  # the seven crud routes tell the application what paths to create && display

  ########################
  # Routes
  ########################

  # the homepage of the site generic index page
  get ('/') do
    render(:erb, :index)
  end


  # the resource page also known as index page for the particular resource
  # established as a get request to server
  # resource is pluralized
  get('/koopas') do
    # an instance variable holding a JSON pasrsed array of all koopas in the redis db
    @koopas = $redis.keys("*koopas*").map { |koopa| JSON.parse($redis.get(koopa)) }
    render(:erb, :"koopas/index")
  end


  # the show page for a single item in the resource
  get('/koopas/:id') do
    id = params[:id]
    unparsed_db_koopa = $redis.get("koopas:#{id}")

    # instance variable used in the show page
    @koopa = JSON.parse(unparsed_db_koopa)
    render(:erb, :"koopas/show")
  end


  # path to create new instance of koopa resource
  get("/koopas/new") do
    render(:erb, :"koopas/new")
  end


  # Server POST request
  post("/koopas") do
  # capturig the values of params from user input
    index = $redis.incr("koopa:index")
    name = params[:name]
    photo_url = params[:photo_url]
    color = params[:color]
    has_shell = params[:has_shell]

    # a new instance of koopa has all the following attrs
    # the id attr is set to take the incremented index number issued by the db
    koopa = {name: name, id: index, has_shell: has_shell, photo_url:photo_url}

    # redis saves a new instace of koopa which we turn to JSON
      $redis.set("koopas:#{index}", koopa.to_json)

    # promt a server 302 redirect telling the browser to do a new get request for index
    redirect to("/koopas")
  end


  # simple get request for edit form page
  # creating path for specific instance of a koopa with their id
  # the koopa varibale will then be parsed by the JSON ruby module
  get('/koopas/:id/edit') do
    id = params[:id]
    unparsed_db_koopa=$redis.get("koopas:#{id}")
    @koopa = JSON.parse(unparsed_db_koopa)
    render(:erb, :"koopas/edit")
  end

  # edits go in as a put verb and need a specific id
  # once the update button pressed, a 302 server status will redirect the browser to get a new page (updated)
  put('/koopas/:id') do
    id = params[:id]
    name = params[:name]
    color = params[:color]
    has_shell = params[:has_shell]
    photo_url = params[:photo_url]

    # edited_koopa holds all the fields to be updated in the db
    edited_koopa = {id: id, name: name, photo_url: photo_url, color:color, has_shell: has_shell}

    # telling redis to set the koopa with a specific id and turning it into a json object for redis to store
    $redis.set("koopas:#{id}", edited_koopa.to_json)
    redirect to("/koopas/#{id}")
  end


  # to delete a koopa no params needed a button on a single koopa page will instruct redis to del an instance in the koopas db
  delete("/koopas/:id") do

    # id variable identifying specific koopa index no
    id = params[:id]

    # telling redis to delete specific koopa id and  issue a 302 redirect to the index page of all koopas
    $redis.del("koopas:#{id}")
    redirect to('/koopas')
  end

end
