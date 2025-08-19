module Tastytrade
  class AuthService
    include HTTParty
    base_uri ENV.fetch("TASTYTRADE_API_URL", "https://api.tastyworks.com")

    def initialize
      @access_token = nil
      @refresh_token = nil
    end

    def authenticate(username:, password:)
      response = self.class.post("/sessions", {
        body: {
          login: username,
          password: password,
          remember_me: true
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      })

      if response.code == 201 || response.code == 200
        data = response.parsed_response

        # TastyTrade returns the token in different places depending on the endpoint
        @access_token = data.dig("data", "session-token") ||
                       data.dig("data", "sessionToken") ||
                       data.dig("session-token") ||
                       data.dig("sessionToken")

        if @access_token
          Rails.cache.write("tastytrade_token_#{username}", @access_token, expires_in: 24.hours)
          Rails.logger.info "TastyTrade authentication successful for #{username}"
          data
        else
          Rails.logger.error "No session token found in response: #{data.inspect}"
          raise AuthenticationError, "No session token in response"
        end
      else
        Rails.logger.error "TastyTrade authentication failed with code #{response.code}: #{response.body}"
        raise AuthenticationError, "Authentication failed: #{response.body}"
      end
    end

    def authenticated_headers(username = nil)
      # Try OAuth token first if available
      if username
        user = User.find_by(tastytrade_username: username) || User.find_by(email: username)
        if user&.tastytrade_oauth_token.present? && user.tastytrade_oauth_expires_at > Time.current
          return { "Authorization" => "Bearer #{user.tastytrade_oauth_token}" }
        end
      end

      # Fallback to session token
      token = @access_token || Rails.cache.read("tastytrade_token_#{username}")
      raise TokenExpiredError, "No valid token found" unless token

      { "Authorization" => "Bearer #{token}" }
    end

    def validate_token(username)
      token = Rails.cache.read("tastytrade_token_#{username}")
      return false unless token

      response = self.class.get("/sessions/validate", {
        headers: { "Authorization" => "Bearer #{token}" }
      })

      response.code == 200
    end

    def logout(username)
      token = Rails.cache.read("tastytrade_token_#{username}")
      return true unless token

      response = self.class.delete("/sessions", {
        headers: { "Authorization" => "Bearer #{token}" }
      })

      Rails.cache.delete("tastytrade_token_#{username}")
      response.code == 204
    end

    class AuthenticationError < StandardError; end
    class TokenExpiredError < StandardError; end
  end
end
