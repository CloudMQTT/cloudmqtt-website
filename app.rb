# encoding: UTF-8
require 'sinatra'
require 'haml'
require 'sass'
require 'redcarpet'

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

helpers do
  def markdown(view, opts = {})
    text = File.read("views/#{view}.md")
    rnder = Redcarpet::Render::HTML.new(:prettify => true)
    mkdwn = Redcarpet::Markdown.new(rnder, {:no_intra_emphasis => true, :fenced_code_blocks => true, :space_after_headers => true}.merge(opts))
    mkdwn.render(text).gsub(/(\<code class=")/, '\1prettyprint ')
  end
end

