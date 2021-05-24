# frozen_string_literal: true

class UserSerializer
  def self.to_hash(model, options = {})
    filtered_options = {
      :only => [:id, :email, :number, :image, :name, :has_opentable_creds, :has_resy_creds, :has_yelp_creds, :has_tock_creds, :created_at]
    }

    filtered_options = filtered_options.update((options or {}))

    model.serializable_hash(filtered_options)
  end
end