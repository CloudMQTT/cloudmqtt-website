# encoding: UTF-8
require 'sinatra'
require 'haml'
require 'sass'

set :haml, :format => :html5
before do
  @dev = true
end

get '/' do
  haml :index, :locals => { name: 'index' }
end

get '/css/flat-ui.css' do
  content_type :css
  sass :'../sass/flat-ui'
end

get '/:page.html' do |page|
  pass unless File.exists? "./views/#{page}.haml"
  haml page.to_sym, :locals => { name: page }
end

not_found do
  haml :'404', locals: { name: '' }
end
