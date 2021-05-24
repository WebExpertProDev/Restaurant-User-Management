# frozen_string_literal: true
require 'json'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :trackable
  include DeviseTokenAuth::Concerns::User

  def has_number
    !self["number"].blank?
  end

  def first_name
    self.name.split[0]
  end

  def last_name
    self.name.split[1]
  end

  def encrypt_password(plaintext_password)
    salt = self.partner_auth_salt
    key_length = ActiveSupport::MessageEncryptor.key_len
    key = ActiveSupport::KeyGenerator.new(ENV["SECRET_KEY_BASE"]).generate_key(salt, key_length)
    crypt = ActiveSupport::MessageEncryptor.new(key)

    crypt.encrypt_and_sign(plaintext_password)
  end

  def decrypt_password(encrypted_password)
    salt = self.partner_auth_salt
    key_length = ActiveSupport::MessageEncryptor.key_len
    key = ActiveSupport::KeyGenerator.new(ENV["SECRET_KEY_BASE"]).generate_key(salt, key_length)
    crypt = ActiveSupport::MessageEncryptor.new(key)

    crypt.decrypt_and_verify(encrypted_password)
  end

  def get_reservations_from_partners
    partners = self.get_authed_partners

    reservation_requests_batch = Typhoeus::Hydra.hydra
    reservation_requests = []
    partners.each do |partner|
      reservation_request = self.get_reservation_from_partner(partner)

      reservation_requests.push(reservation_request)
      reservation_requests_batch.queue(reservation_request)
    end
    reservation_requests_batch.run

    reservations = []
    reservation_requests.each do |request|
      reservations.concat(JSON.parse(request.response.body))
    end

    reservations
  end

  def get_reservation_from_partner(partner)
      uri = URI::HTTP.build(host: $loader_host, port: $loader_port, path: "/reservations/#{partner}")
      params = {
        auth_data: self.get_auth_data(partner)
      }
      Typhoeus::Request.new(uri, headers: { 'Content-Type' => 'application/json'}, method: :post, body: JSON.dump(params))
  end

  def get_authed_partners
    authed_partners = []
    Restaurant::Partners.values.each do |partner|
      key = Restaurant.get_partner_creds_id(partner)
      if self[key]
        authed_partners << partner
      end
    end
    authed_partners
  end

  def get_user_data(partner)
    if partner == Restaurant::Partners[:RESY]
      JSON.parse(self["resy_user_data"])
    elsif partner == Restaurant::Partners[:OPENTABLE]
      JSON.parse(self["opentable_user_data"])
    elsif partner == Restaurant::Partners[:TOCK]
      JSON.parse(self["tock_user_data"])
    else
      raise "Partner not recognized: #{partner}"
    end
  end

  def get_auth_data(partner)
    if partner == Restaurant::Partners[:RESY]
      encrypted_auth_data = JSON.parse(self["resy_auth_data"])
    elsif partner == Restaurant::Partners[:OPENTABLE]
      encrypted_auth_data = JSON.parse(self["opentable_auth_data"])
    elsif partner == Restaurant::Partners[:TOCK]
      encrypted_auth_data = JSON.parse(self["tock_auth_data"])
    else
      raise "Partner not recognized: #{partner}"
    end
    {
      "username": encrypted_auth_data["username"],
      "password": self.decrypt_password(encrypted_auth_data["password"])
    }
  end

  def encrypted_password_changed?
    false
  end

  class << self
  end

end
