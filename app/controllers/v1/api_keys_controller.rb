class V1::ApiKeysController < ApplicationController
  # Thanks to: Implemented along the tutorial https://keygen.sh/blog/how-to-implement-api-key-authentication-in-rails-without-devise/
 
  include ApiKeyAuthenticatable 
 
  # Require API key authentication                             
  prepend_before_action :authenticate_with_api_key!, only: %i[index destroy] 
 
  # Optional token authentication for logout                           
  #prepend_before_action :authenticate_with_api_key, only: [:destroy] 
  
  def index
    render json: current_bearer.api_keys 
  end
 
  def create
    # This leads to a classical login method which then assigns a token.
    authenticate_with_http_basic do |randname, password| 
      #user = User.find_by email: email 
      persistaccount=Persistaccount.find_by randname: randname
      if persistaccount&.authenticate(password) 
        api_key = persistaccount.api_keys.create! token: SecureRandom.hex 
        render json: api_key, status: :created and return 
      end
    end
    head :unauthorized # if above does not lead to result
  end
 
  def destroy
    # Call api-key/id in delete request
    api_key = current_bearer.api_keys.find(params[:id]) 
    api_key.destroy 
    #current_api_key&.destroy
  end
end