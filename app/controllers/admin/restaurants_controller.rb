# frozen_string_literal: true

class Admin::RestaurantsController < Admin::ApplicationController
  private

  def model
    Restaurant
  end

  def serialize(user)
    RestaurantSerializer.to_hash(user)
  end

  def attributes
    params.permit(:name, :is_hidden, :cuisines, :price_band, :neighborhood)
  end
end
