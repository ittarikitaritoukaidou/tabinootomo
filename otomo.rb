$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'model/tabi'
require 'model/activity'

Mongoid.load!('mongoid.yaml')

class OtomoApp < Sinatra::Base
  helpers Sinatra::JSON

  STATIC_EXPIRES = 3600*24*365

  before do
    redirect to('/').sub(/https?/i, 'https'), 301 if request.scheme == 'http' && ENV['RACK_ENV'] == 'production'
  end

  configure :development do
    register Sinatra::Reloader
    also_reload 'lib/*.rb'
  end

  configure :production do
    require 'newrelic_rpm'
  end

  configure do
    set :erb, :escape_html => true
    set :scss, {:style => :compact, :debug_info => false}

    set :static_cache_control, [:public, :max_age => STATIC_EXPIRES]
  end

  helpers do
    def csrf_token
      session[ :csrf ] ||= SecureRandom.hex( 32 )
    end

    def require_tabi
      begin
        @tabi = Tabi.find(params[:tabi_id])
        @title = @tabi.title
        @description = @tabi.memo
      rescue
        redirect to '/'
      end
    end

    def rich_text(text)
      breaked_line = text.gsub("\n", '<br>')
      linked = Rinku.auto_link(breaked_line, :urls, 'target="_blank" rel="nofollow"', skip_tags=nil)
      Sanitize.fragment(linked, Sanitize::Config.merge(Sanitize::Config::BASIC,
          :add_attributes => {
            'a' => {
              'target' => '_blank',
              }
            }
      ))
    end

    def require_activity
      begin
        @activity = Activity.find(params[:activity_id])
        raise "not match" unless @tabi.has_activity?(@activity)

        @title = @activity.title
        @description = @activity.memo
      rescue
        redirect to @tabi ? @tabi.path : '/'
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
    @page_id = 'tabi_edit'
    require_tabi
    @back_to = @tabi.path

    erb :tabi_edit
  end

  post '/tabi/:tabi_id/edit' do
    @page_id = 'tabi_edit'
    require_tabi

    @tabi.title = params[:title]
    @tabi.memo = params[:memo]

    activity_ids = @tabi.activity_ids

    if params[:activity_id]
      @tabi.activity_ids = params[:activity_id].map{|_id|
        _id = BSON::ObjectId.from_string(_id)
      }.map{|_id|
        activity_ids.find{|__id|
          __id == _id
        }
      }.compact
    end

    @tabi.save

    redirect to @tabi.path
  end

  post '/tabi/:tabi_id/delete' do
    require_tabi

    @tabi.activities.each{|activity|
      activity.destroy
    }
    @tabi.destroy

    redirect to '/'
  end

  post '/tabi/:tabi_id/activities' do
    require_tabi
    activity = @tabi.append_activity params[:title], params[:location]

    redirect to activity.edit_path
  end

  get '/tabi/:tabi_id/activities/:activity_id' do
    @page_id = 'activity'
    require_tabi
    require_activity

    unless @activity.has_any_detail?
      redirect to @activity.edit_path
    end

    @back_to = @tabi.path

    erb :activity
  end

  get '/tabi/:tabi_id/activities/:activity_id/edit' do
    @page_id = 'activity_edit'
    require_tabi
    require_activity

    if @activity.has_any_detail?
      @back_to = @activity.path
    else
      @back_to = @tabi.path
    end

    erb :activity_edit
  end

  post '/tabi/:tabi_id/activities/:activity_id/edit' do
    require_tabi
    require_activity

    @activity.title = params[:title]
    @activity.memo = params[:memo]
    @activity.location = params[:location]

    @activity.save

    redirect to @tabi.path
  end

  post '/tabi/:tabi_id/activities/:activity_id/delete' do
    require_tabi
    require_activity

    @tabi.delete_activity(@activity)

    redirect to @tabi.path
  end

  # -----

  get '/style' do
    expires STATIC_EXPIRES, :public, :must_revalidate
    scss :'scss/main', Compass.sass_engine_options
  end

  get '/js/vendors' do
    expires STATIC_EXPIRES, :public, :must_revalidate
    source = %w(
      jquery/dist/jquery.min.js
      underscore/underscore-min.js
      jquery-ui/ui/core.js
      jquery-ui/ui/widget.js
      jquery-ui/ui/mouse.js
      jquery-ui/ui/sortable.js
      jqueryui-touch-punch/jquery.ui.touch-punch.min.js
    ).map{|path|
      open('public/js/vendor/' + path).read
    }.join("\n\n")

    content_type 'application/javascript'
    source
  end

  get '/js' do
    expires STATIC_EXPIRES, :public, :must_revalidate
    coffee :'coffee/tabi'
  end
end
