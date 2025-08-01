module Tastytrade
  class AuthService
    include HTTParty
    base_uri ENV.fetch('TASTYTRADE_API_URL', 'https://api.tastyworks.com')

    def initialize
      @access_token = nil
      @refresh_token = nil
    end

    def authenticate(username:, password:)
      response = self.class.post('/sessions', {
        body: {
          login: username,
          password: password
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      })

      if response.code == 201
        data = response.parsed_response
        @access_token = data.dig('data', 'session-token')
        Rails.cache.write("tastytrade_token_#{username}", @access_token, expires_in: 24.hours)
        data
      else
        raise AuthenticationError, "Authentication failed: #{response.body}"
      end
    end

    def authenticated_headers(username = nil)
      token = @access_token || Rails.cache.read("tastytrade_token_#{username}")
      raise TokenExpiredError, "No valid token found" unless token

      { 'Authorization' => "Bearer #{token}" }
    end

    def validate_token(username)
      token = Rails.cache.read("tastytrade_token_#{username}")
      return false unless token

      response = self.class.get('/sessions/validate', {
        headers: { 'Authorization' => "Bearer #{token}" }
      })

      response.code == 200
    end

    def logout(username)
      token = Rails.cache.read("tastytrade_token_#{username}")
      return true unless token

      response = self.class.delete('/sessions', {
        headers: { 'Authorization' => "Bearer #{token}" }
      })

      Rails.cache.delete("tastytrade_token_#{username}")
      response.code == 204
    end

    class AuthenticationError < StandardError; end
    class TokenExpiredError < StandardError; end
  end
end