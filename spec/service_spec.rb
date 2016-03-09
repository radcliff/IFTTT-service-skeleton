require_relative 'spec_helper'
require_relative '../service.rb'

describe Service do
  include Rack::Test::Methods

  def app
    Service
  end

  describe 'conformms to IFTTT channel protocol:' do
    context '/status' do
      it 'exists' do
        header 'IFTTT-Channel-Key', ENV['IFTTT_CHANNEL_KEY']
        get '/ifttt/v1/status'
        expect(last_response.status).to eq(200)
      end

      it 'returns 401 with an invalid channel key' do
        get '/ifttt/v1/status', nil
        expect(last_response.status).to eq(401)
      end

    end
  end

end
