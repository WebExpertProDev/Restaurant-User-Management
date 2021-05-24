require 'net/http'
require 'json-schema'
require 'json'

class AuthController < ApplicationController
  before_action :authenticate_user!

  def partner_auth
    is_valid = validate_partner_auth_params
    if !is_valid
      return
    end
    partner = params[:partner]

    begin
      response = backend_partner_auth(
          username: params["username"],
          password: params["password"],
          partner: partner
        )
      creds = {
        username: params["username"],
        password: current_user.encrypt_password(params["password"])
      }.to_json
      response = JSON.parse(response)
      if partner == Restaurant::Partners[:OPENTABLE]
        current_user.opentable_auth_data = creds
        current_user.opentable_user_data = response.to_json
        current_user.has_opentable_creds = true
        current_user.save!
      elsif partner == Restaurant::Partners[:RESY]
        current_user.resy_auth_data = creds
        current_user.resy_user_data = response.to_json
        current_user.has_resy_creds = true
        current_user.save!
      elsif partner == Restaurant::Partners[:TOCK]
        current_user.tock_auth_data = creds
        current_user.tock_user_data = response.to_json
        current_user.has_tock_creds = true
        current_user.save!
      end
      return json_response({
        "status": "success",
        "data": current_user
      })
    rescue => e
      logger.info("error")
      logger.info(e)
      logger.info(e.backtrace)
      json_response({ error: "Error authing partner" }, :bad_request)
    end
  end

  private

  def backend_partner_auth(username:, password:, partner:)
    http = Net::HTTP.new($loader_host, $loader_port)
    body = {
      username: username,
      password: password,
      partner: partner
    }.to_json
    response = http.post(
      "partner-auth",
      body,
      'Content-Type' => 'application/json'
    )

    if response.code == "200"
      response.body
    else
      raise 'Err'
    end
  end

  def validate_partner_auth_params
    if request.headers['Content-Type'] != 'application/json'
      json_response({ error: "need json" })
      return false
    end
    schema = {
      "type" => "object",
      "required" => ["username", "password", "partner"],
      "properties" => {
        "partner" => {
          "type": "string"
        },
        "username" => {
          "type": "string"
        },
        "password" => {
          "type": "string"
        },
      }
    }
    begin
      json_data = JSON.parse(request.raw_post)
      if !JSON::Validator.validate(schema, json_data)
        json_response({ error: "data no good" })
        return false
      end
    rescue JSON::ParserError
      json_response({ error: "need json" })
      return false
    end
    return true
  end
end
