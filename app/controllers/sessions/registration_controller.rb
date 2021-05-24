require 'koala'
require 'securerandom'

class Sessions::RegistrationController < DeviseTokenAuth::RegistrationsController
  def create
    return login_with_email_and_password if params.has?(:email) and params.has?(:password)
    login_with_facebook
  end

  private

  def login_with_email_and_password
    user = User.find_by_email(params[:email])

    unless user && user.valid_password?(params[:password])
      return json_response({ error: "Unknown email / password combination" }, :bad_request)
    end

    successful_with user
  end

  def login_with_facebook
    access_token = params["access_token"]
    number = params["number"]

    begin
      graph = Koala::Facebook::API.new(access_token)
      profile = graph.get_object("me", fields: ['email', 'name', 'picture.type(normal)'])
    rescue Koala::Facebook::AuthenticationError => e
      return json_response({ error: "Bad auth token" }, :bad_request)
    end

    email = profile["email"]

    user_exists = User.exists?(email: email)
    # Registration requires number
    if !user_exists
      if number.blank?
        return json_response({ error: "Number required" }, :bad_request)
      end
    end
    user = User.find_or_create_by(email: email)

    # Regardless of login or registration, assign these new values
    user.image = profile["picture"]["data"]["url"]
    user.name = profile["name"]
    user.access_token = access_token

    if !user_exists
      # Only run on registration
      user.partner_auth_salt = SecureRandom.hex(64)
    end

    if !number.blank?
      user.number = number
    end

    user.save!

    if !user_exists
      # Only run on registration
      Collection.create_user_defaults!(user_id: user.id)
    end

    successful_with user
  end

  def successful_with(user)
    @resource = user
    @token = @resource.create_token
    @resource.save!
    update_auth_header
    render_create_success
  end
end
