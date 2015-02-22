$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'model/tabi'
require 'model/activity'

Mongoid.load!('mongoid.yaml')

class OtomoApp < Sinatra::Base
  helpers Sinatra::JSON

  configure :development do
    register Sinatra::Reloader
    also_reload 'lib/*.rb'
  end

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
        @title = @tabi.title
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
    @page_id = 'tabi_edit'
    require_tabi

    erb :tabi_edit
  end

  post '/tabi/:tabi_id/edit' do
    @page_id = 'tabi_edit'
    require_tabi

    @tabi.title = params[:title]

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
    activity = @tabi.append_activity params[:title]

    redirect to @tabi.path
  end

  get '/tabi/:tabi_id/activities/:activity_id' do
    @page_id = 'activity'
    require_tabi
    require_activity

    erb :activity
  end

  get '/tabi/:tabi_id/activities/:activity_id/edit' do
    @page_id = 'activity_edit'
    require_tabi
    require_activity

    erb :activity_edit
  end

  post '/tabi/:tabi_id/activities/:activity_id/edit' do
    require_tabi
    require_activity

    @activity.title = params[:title]
    @activity.memo = params[:memo]

    @activity.save

    redirect to @activity.path
  end

  post '/tabi/:tabi_id/activities/:activity_id/delete' do
    require_tabi
    require_activity

    @tabi.delete_activity(@activity)

    redirect to @tabi.path
  end

  # -----

  get '/style' do
    scss :'scss/main', Compass.sass_engine_options
  end

  get '/js' do
    coffee :'coffee/tabi'
  end
end
