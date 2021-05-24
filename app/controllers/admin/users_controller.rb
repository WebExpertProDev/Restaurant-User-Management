# frozen_string_literal: true

class Admin::UsersController < Admin::ApplicationController
  private

  def model
    User
  end

  def serialize(user)
    UserSerializer.to_hash(user)
  end

  def attributes
    params.permit(:email, :number, :name)
  end
end
