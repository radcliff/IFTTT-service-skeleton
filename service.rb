class Service < Sinatra::Base
  register Sinatra::Contrib
  register Sinatra::Session
  helpers  Sinatra::Param

  configure do
    set :IFTTT_CHANNEL_SLUG,  ENV['IFTTT_CHANNEL_SLUG']
    set :IFTTT_CHANNEL_KEY,   ENV['IFTTT_CHANNEL_KEY']
    set :IFTTT_CLIENT_ID,     ENV['IFTTT_CLIENT_ID']
    set :IFTTT_CLIENT_SECRET, ENV['IFTTT_CLIENT_SECRET']
    set :IFTTT_REDIRECT_URI,  ENV['IFTTT_REDIRECT_URI']

    # set :session_name,   ''  # TODO: customize session cookie name
    set :session_secret, ENV['SESSION_SECRET']
  end

  helpers do
    def default_headers
      headers['Content-Type'] = 'application/json;charset=utf-8'
    end

    def error_response(message="Something went wrong!")
      default_headers
      halt 401, json( { errors: [ { message: message } ] } )
    end

    def valid_channel_key
      unless env['HTTP_IFTTT_CHANNEL_KEY'] == settings.IFTTT_CHANNEL_KEY
        error_response "Invalid IFTTT Channel Key!"
      end
    end

    def valid_access_token
      authorization = request.env['HTTP_AUTHORIZATION']
      bearer_token = /Bearer (.*)\z/i.match(authorization).captures[0]

      # # TODO: verify access token is valid
      # unless user = lookup_user_with_access_token bearer_token
      #   error_response "Invalid access token!"
      # end
    end
  end

  get '/' do
    redirect '/login' unless session?

    @username = session[:username]
    erb :index
  end

  namespace '/login' do
    get do
      redirect '/' if session?

      @redirect_path = params[:r]  # encoded authorization request url
      erb :login
    end

    post do
      param :username, String, require: true
      param :password, String, require: true

      # TODO: authenticate user

      session_start!
      session[:username] = params[:username]

      if redirect_path = params[:redirect]
        redirect to(CGI.unescape redirect_path)
      else
        redirect to('/')
      end
    end
  end

  namespace '/oauth' do
    get '/authorize' do
      param :client_id,     String, is: settings.IFTTT_CLIENT_ID
      param :response_type, String, is: 'code'
      param :scope,         String, is: 'ifttt'
      param :state,         String, require: true
      param :redirect_uri,  String, is: settings.IFTTT_REDIRECT_URI

      unless session?
        url = CGI.escape request.url
        redirect to("/login?r=#{url}")
      end

      session[:state] = params[:state]

      erb :authorize
    end

    post '/token' do
      param :grant_type,    String, is: 'authorization_code'
      param :code,          String, required: true
      param :client_id,     String, is: settings.IFTTT_CLIENT_ID
      param :client_secret, String, is: settings.IFTTT_CLIENT_SECRET
      param :redirect_uri,  String, is: settings.IFTTT_REDIRECT_URI

      code = params[:code]

      # # TODO: verify authorization code is valid
      # error_response "Invalid authorization code!" unless valid_authorization_code code

      tokens = {
        access_token: '',  # token IFTTT will use when making authenticated calls
        token_type: 'Bearer'
      }

      default_headers
      json tokens
    end
  end

  namespace '/authorize/ifttt' do
    get '/accept' do
      code = ''  # TODO: an opaque string that will be exchange for a Bearer token by IFTTT
      state = session[:state]

      redirect to("https://ifttt.com/channels/#{settings.IFTTT_CHANNEL_SLUG}/authorize?code=#{code}&state=#{state}")
    end

    get '/decline' do
      redirect to("https://ifttt.com/channels/#{settings.IFTTT_CHANNEL_SLUG}/authorize?error=access_denied")
    end
  end

  namespace '/ifttt' do
    namespace '/v1' do

      before do
      end

      get '/status' do
        valid_channel_key
        status 200
      end

      get '/user/info' do
        valid_access_token

        data = {
          id:   '',  # identification to display to the user
          url:  '',  # URL to user’s dashboard or configuration page on your service’s website
          name: ''   # identification to display to the user
        }

        default_headers
        json data: data
      end

      namespace '/webhooks' do
        post '/applet_enabled' do
          valid_access_token

          param :user_id,    String,  required: true
          param :applet_id,  String,  required: true
          param :enabled_at, Integer, required: true
          param :token,      String,  required: true

          # TODO: persist user access token

          status 200
        end

        post '/applet_disabled' do
          valid_channel_key

          param :user_id,     String,  required: true
          param :applet_id,   String,  required: true
          param :disabled_at, Integer, required: true

          # TODO: destroy user access token & channel connection

          status 200
        end
      end

    end
  end

end
