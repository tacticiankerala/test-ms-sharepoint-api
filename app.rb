require 'sinatra'
require 'sharepoint-ruby'
require 'sharepoint-http-auth'

enable :sessions

HOST = 'localhost:8000'
PROTOCOLE = 'http'

get '/' do
  erb :creds
end

post '/folders' do
  store_creds_in_session(params[:username], params[:password], params[:site_name])
  with_site do |site|
    @folders = site.folders
    erb :folders
  end
end

get '/folders' do
  with_site do |site|
    @folders = site.folders
    erb :folders
  end
end

get '/folders/:name' do
  with_site do |site|
    @folder = site.folder params[:name]
    @files = @folder.files
    erb :files
  end
end

get '/folders/:folder/files/:file' do
  with_site do |site|
    @folder = site.folder params[:folder]
    uri = PROTOCOLE + '://' + HOST + URI.parse(@folder.data['__metadata']['uri']).path + "/files/getbyurl('#{URI::encode(params[:file])}')"
    @file = site.query :get, uri
    erb :file
  end
end

def store_creds_in_session(username, password, site_name)
  session[:username], session[:password], session[:site_name] = username, password, site_name
end

def with_site
  site = Sharepoint::Site.new HOST, session[:session_name]
  site.session = Sharepoint::HttpAuth::Session.new site
  site.protocole = PROTOCOLE
  site.session.authenticate session[:username], session[:password]
  unless site.folders.empty?
    yield site
  else
    erb :error
  end
end
