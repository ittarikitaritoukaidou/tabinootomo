$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'model/tabi'

Mongoid.load!('mongoid.yaml')

class OtomoApp < Sinatra::Base

  configure do
    set :erb, :escape_html => true
    set :scss, {:style => :compact, :debug_info => false}
  end

  helpers do
    def csrf_token
      session[ :csrf ] ||= SecureRandom.hex( 32 )
    end

    def require_tabi
      begin
        @tabi = Tabi.find(params[:tabi_id])
      rescue
        redirect to '/'
      end
    end

  end

  get '/' do
    @page_id = 'index'
    erb :index
  end

  post '/tabi/create' do
    tabi = Tabi.new({
        title: params[:title],
      })
    tabi.save

    redirect to(tabi.path)
  end

  get '/tabi/:tabi_id' do
    @page_id = 'tabi'
    require_tabi

    erb :tabi
  end

  get '/tabi/:tabi_id/edit' do
    @page_id = 'tabi'
    require_tabi

    erb :tabi_edit
  end

  post '/tabi/:tabi_id/edit' do
    @page_id = 'tabi_edit'
    require_tabi

    @tabi.title = params[:title]
    @tabi.save

    redirect to @tabi.path
  end


  get '/style' do
    scss :'scss/main', Compass.sass_engine_options
  end

  get '/js' do
    coffee :'coffee/tabi'
  end
end
