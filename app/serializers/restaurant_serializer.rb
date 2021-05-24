# frozen_string_literal: true

class RestaurantSerializer
  def self.to_hash(model, options = {})
    model.attributes
  end
end