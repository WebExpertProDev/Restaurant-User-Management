class CollectionsController < ApplicationController
  before_action :authenticate_user!

  def list
    collection_id = params[:id]
    collection = Collection.find_by(user_id: current_user.id, id: collection_id)
    if collection.nil?
      return json_response({ error: "Collection does not exist or does not belong to user" }, :bad_request)
    end

    json_response(collection.to_json(:include => {restaurants: { only: [:id, :name] } }))
  end

  def list_all
    collections = Collection.where(:user_id => current_user.id)
    json_response(collections.to_json(:include => {restaurants: { only: [:id, :name] } }))
  end

  def create
    name = params["name"]
    begin
      collection = Collection.create!(
        name: name,
        user_id: current_user.id
      )
    rescue ActiveRecord::RecordNotUnique => e
      return json_response({ error: "This user already has a collection with that name" }, :bad_request)
    end
    json_response(collection.to_json)
  end

  def delete
    collection_id = params[:id]
    collection = Collection.find_by(user_id: current_user.id, id: collection_id)
    if collection.nil?
      return json_response({ error: "Collection does not exist or does not belong to user" }, :bad_request)
    end
    collection.restaurants.clear
    collection.delete

    ok_response
  end

  def add_restaurants
    collection_id = params[:id]
    restaurants_to_add = params["restaurants"]

    collection = Collection.find_by(user_id: current_user.id, id: collection_id)
    if collection.nil?
      return json_response({ error: "Collection does not exist or does not belong to user" }, :bad_request)
    end

    restaurants_to_add.each do |r_id|
      restaurant = Restaurant.find_by_id(r_id)
      if restaurant.nil?
        return json_response({ error: "Restaurant does not exist: #{r_id.to_s}" }, :bad_request)
      end
      begin
        collection.restaurants << restaurant
      rescue ActiveRecord::RecordNotUnique => e
        # Ignore
      end
      RestaurantUser.create!(restaurant_id: r_id, user_id: current_user.id)
    end

    json_response(collection.to_json(:include => {restaurants: { only: [:id, :name] } }))
  end

  def remove_restaurants
    collection_id = params[:id]
    restaurants_to_remove = params["restaurants"]

    collection = Collection.find_by(user_id: current_user.id, id: collection_id)
    if collection.nil?
      return json_response({ error: "Collection does not exist or does not belong to user" }, :bad_request)
    end

    restaurants_to_remove.each do |r_id|
      restaurant = Restaurant.find_by_id(r_id)
      if restaurant.nil?
        return json_response({ error: "Restaurant does not exist: #{r_id.to_s}" }, :bad_request)
      end
      begin
        collection.restaurants.delete(restaurant)
      rescue ActiveRecord::RecordNotFound => e
        # Ignore
      end
      join_association = RestaurantUser.find_by(restaurant_id: r_id, user_id: current_user.id)
      join_association.destroy
    end

    json_response(collection.to_json(:include => {restaurants: { only: [:id, :name] } }))
  end

end
