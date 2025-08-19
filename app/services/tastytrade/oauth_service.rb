module Tastytrade
  class OAuthService
    include HTTParty
    base_uri ENV.fetch("TASTYTRADE_API_URL", "https://api.tastyworks.com")

    def exchange_code_for_token(code, redirect_uri)
      response = self.class.post("/oauth/token", {
        body: {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri,
          client_id: ENV["TASTYTRADE_CLIENT_ID"],
          client_secret: ENV["TASTYTRADE_CLIENT_SECRET"]
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      })

      if response.code == 200
        data = response.parsed_response
        {
          success: true,
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          expires_in: data["expires_in"] || 3600,
          token_type: data["token_type"]
        }
      else
        Rails.logger.error "OAuth token exchange failed: #{response.body}"
        {
          success: false,
          error: response.body
        }
      end
    rescue => e
      Rails.logger.error "OAuth token exchange error: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end

    def refresh_token(refresh_token)
      response = self.class.post("/oauth/token", {
        body: {
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: ENV["TASTYTRADE_CLIENT_ID"],
          client_secret: ENV["TASTYTRADE_CLIENT_SECRET"]
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      })

      if response.code == 200
        data = response.parsed_response
        {
          success: true,
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          expires_in: data["expires_in"] || 3600,
          token_type: data["token_type"]
        }
      else
        Rails.logger.error "OAuth token refresh failed: #{response.body}"
        {
          success: false,
          error: response.body
        }
      end
    rescue => e
      Rails.logger.error "OAuth token refresh error: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end
end
