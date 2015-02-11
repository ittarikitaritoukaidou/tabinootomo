$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

class OtomoApp < Sinatra::Base

  configure do
    set :erb, :escape_html => true
    set :scss, {:style => :compact, :debug_info => false}
  end

  def csrf_token
    session[ :csrf ] ||= SecureRandom.hex( 32 )
  end

  get '/' do
    erb :index
  end

  get '/style' do
    scss :'scss/main', Compass.sass_engine_options
  end

  get '/js' do
    coffee :'coffee/tabi'
  end
end
