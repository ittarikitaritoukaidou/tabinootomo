$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

class OtomoApp < Sinatra::Base
  set :erb, :escape_html => true

  def csrf_token
    session[ :csrf ] ||= SecureRandom.hex( 32 )
  end

  get '/' do
    '旅!!!'
  end
end
