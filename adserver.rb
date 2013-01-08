$LOAD_PATH.unshift(File.dirname(__FILE__)) #used to point ruby to the current directory cause 1.9 doesnt work in the project's current directory
require 'rubygems' # the usuals.
require 'sinatra'
require 'data_mapper' #require the data_mapper gem instead of just certain gems from it. 
require 'lib/authorization'



DataMapper::setup(:default, "sqlite://#{Dir.pwd}/adserver.db") # setup function creates the database. sqlite type. path is specified as current path. 

class Ad #defining Ad as a class with certain attributes.
  include DataMapper::Resource # the Ad model is going to be persistent. so include DataMapper::Resource. 
  property :id, Serial #auto increment key
  property :title, String
  property :content, String
  property :width, Integer
  property :height, Integer
  property :filename, String
  property :url, String
  property :is_active, Boolean
  property :created_at, DateTime
  property :updated_at, DateTime
  property :size, Integer
  property :content_type, String
  has n, :clicks #associations. an Ad has-many clicks. so one-to-many is used here.  
end
class Click # even clicks have attributes man! they show the ip_address and the date they were clicked.
  include DataMapper::Resource
  property :id, Serial
  property :ip_address, String
  property :created_at, DateTime
  belongs_to :ad # another association. Clicks belongs_to Ad. Get it? 
end

def handle_upload(file) 
  self.content_type = file[:type]
  self.size = File.size(file[:tempfile])
  path = File.join(Dir.pwd, "/public/ads",self.filename)
File.open(path, "wb") do |f|
  f.write(file[:tempfile].read)
end
end

configure :development do #differntiates between Dev Vs Production mode. Good practice
  DataMapper.auto_upgrade! # Upgrades the database each time the app is run. auto_migrate! creates a new database each time you run the app
end


  helpers do 
    include Sinatra::Authorization # Genereic Authorization gem. Can use other gems like OmniAuth also.  
  end
  


  before do #before is a filter that will run code in this block before every event. 
    headers "Content-Type" => "text/html; charset=utf-8" # setting utf-8 for all outgoing content. recommended.
end
  
  get '/' do # this is the homepage
    @title="Welcome to the AdServer." # title
    erb :welcome #call to the .erb file 
  end
  
  get '/ad' do # the second route, displays the ad. 
    id = repository(:default).adapter.query('SELECT id FROM ads ORDER BY random() LIMIT 1;') #returns the adapter used by the repository and lets you make a manual query to the database  
 # it selects one random ad from ads by random. remember foxbase, its that shizz here.
  @ad=Ad.get(id)  #uses get() method from DataMapper. gets the particular ad having ID=id. haha.
  erb :ad, :layout => false #ad erb file is called. the default layout is set false.  
  end
  
  get '/list' do #lists the ads that are already in the server. 
    require_admin # require_admin method based on Sinatara::Authorizaiton, requires you to enter username and password.  
    @title = "List Ads" # title is displayed
    @ads= Ad.all(:order =>[:created_at.desc]) #fetch the list of Ads and the :order is conditioned to be in desecending order of created_at DateTime variable. 
    erb :list # display list.erb, the html fronted of the app.
  end
  
  get '/new' do # creates a new ad. 
    require_admin # used for authenticating using Sinatra::Authorization.
    @title = "Create A New Ad" 
    erb :new # show the new.erb file.
     
  end
  
  post'/create' do # create ads
    require_admin # Sinatra::Authorization
    @ad= Ad.new(params[:ad]) # a new @ad instance is created of the Ad class with id as :ad 
   @ad.handle_upload(parms[:image]) # refer to definition of the method above. it handles such things as storing the file, etc.
   
    if @ad.save #saves the object to the database.the if statement executes the code and checks for errors if no then 

  redirect "/show/#{@ad.id}" # redirect is a Sinatra method to redirect the user to the show page with the respective ad. 
else 
  redirect ('/list') # this merely shows the list, means things are not saved properly. You need to tell the user that the code hasnt exectued well.
end
end

  
  get '/delete/:id' do #delete the ad based on the id.
    require_admin # this also requires authentication to delete an Ad.
    ad=Ad.get(params[:id]) #uses the get method in sinatra to retrieve data from the database based on the Ad :id.
    if ad.nil? #if the object is nil.
      path=File.join(Dir.pwd,"/public/ads",ad.filename) #obtain the file path - Current working dir+/public/ads+the filename obtained from the ORM.
      File.delete(path) #this is the Ruby delete method.
      ad.delete # delete the object
    end
    redirect('/list') # take them back to the /list route. 
  end
  
  get '/show/:id' do # this will show the list of ads that are there in the database
    require_admin # requires authentication.
    @ad = Ad.get(params[:id]) #uses the get method to retrieve the ad based on the id.
    if @ad #if the ad exists.
      erb :show # call the show.erb file.
    else
      redirect('/list') #redirect to list.
    end
      end
  
  get '/click/:id' do #this route is used to count the number of clicks. 
    ad=Ad.get(params[:id]) #get method used to obatin the nesscary ad from the database
    ad.clicks.create(:ip_address => env["REMOTE_ADDR"]) #check the has-many relationship in the definition of the model, one ad has many clicks. accessible with the '.'operator.
	#the ad.clicks.create creates a new record in the database of clicks and assigns the ip address as that of the remote computer.     
redirect(ad.url) #redirects to url of the ad. :)
  end
  #the end. 

