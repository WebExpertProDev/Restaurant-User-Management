class Collection < ApplicationRecord
  has_and_belongs_to_many :restaurants

  USER_DEFAULTS_NAMES = ["Favorites"]

  class << self
    def get_collections_for_restaurant(restaurant_id:, user_id:)
      return Collection.joins(:collections_restaurants).where(:collections_restaurants => { :restaurant_id => restaurant_id }, user_id: user_id)
    end

    def create_user_defaults!(user_id:)
      USER_DEFAULTS_NAMES.each do |name|
        Collection.create(name: name, user_id: user_id)
      end
    end
  end
end
