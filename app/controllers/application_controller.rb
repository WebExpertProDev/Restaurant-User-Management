class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Response

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log

  protected

  def log
    logger.info("AUTH HEADERS---------------------")
    logger.info("access-token: #{request.headers['access-token']}")
    logger.info("client: #{request.headers['client']}")
    logger.info("uid: #{request.headers['uid']}")
    logger.info("---------------------")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:number, :access_token])
  end
end
