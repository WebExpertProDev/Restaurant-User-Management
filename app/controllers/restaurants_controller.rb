# frozen_string_literal: true

require 'json'
require 'net/http'

class RestaurantsController < ApplicationController
  include RedisLib

  before_action :validate_filter_params, only: [:filter]
  before_action :authenticate_user!

  DEFAULT_SEARCH_DISTANCE = 25
  DEFAULT_OFFSET = 0
  DEFAULT_LIMIT = 10
  MAX_SEARCH_DISTANCE = 100
  MAX_LIMIT = 50

  def detail
    restaurant_id = params[:id]
    begin
      restaurant = Restaurant.find(restaurant_id)
    rescue ActiveRecord::RecordNotFound
      return not_found
    end

    restaurant.add_details! unless restaurant.has_details?

    r_json = JSON.parse(restaurant.to_json(only: Restaurant::TOP_LEVEL_FIELDS))

    if params[:datetime] && params[:cover]
      datetime = Time.at(params[:datetime].to_i).strftime('%Y-%m-%dT%H:%M')
      request = restaurant.request_availabilities(datetime: datetime, cover: params[:cover], restaurant_json: r_json)
      request.run
    end

    restaurant_collections = Collection.get_collections_for_restaurant(restaurant_id: restaurant.id, user_id: current_user.id)
    r_json['collections'] = restaurant_collections.pluck('id, name').map { |id, name| { id: id, name: name } }

    json_response(r_json)
  end

  def filter
    unix_datetime_param = params[:datetime]
    location_param = params[:location]
    cover = params[:cover]
    limit = params[:limit] ? params[:limit].to_i : DEFAULT_LIMIT
    distance = params[:distance] ? params[:distance].to_f : DEFAULT_SEARCH_DISTANCE
    offset = params[:offset] ? params[:offset].to_i : DEFAULT_OFFSET

    # Optional filters
    search_text = params[:search_text] ? params[:search_text].downcase : ''
    cuisines = params[:cuisines] || []
    price = params[:price] ? params[:price].map(&:to_i) : []
    neighborhood = params[:neighborhood] ? params[:neighborhood].downcase : ''

    # 2019-10-31T17:00
    datetime = Time.at(unix_datetime_param.to_i).strftime('%Y-%m-%dT%H:%M')

    lat_long = location_param.split(',')
    lat = lat_long[0]
    long = lat_long[1]

    should_query = RestaurantQueryCenter.should_query(latitude: lat, longitude: long, datetime: DateTime.now)
    if should_query && (offset == DEFAULT_OFFSET)
      puts('getting new restaurants')
      t1 = Time.now
      Restaurant.get_new_restaurants(cover: cover, datetime: datetime, latitude: lat, longitude: long)
      t2 = Time.now
      getting_restaurants_time = t2 - t1
    end

    # Adding 1 makes sure that created_at captures the database saves that happen within this request
    # Otherwise, maybe race condition where times are equal
    created_before = params[:created_before] ? params[:created_before].to_i : Time.now.to_i + 1

    # Get only the ones in proximity
    # Filter by created time to make sure results are stable given restaurant updates
    # No limit should be fine. There's a relatively small upper bound for # of restaurants in min(distance_param, 100) mile radius
    restaurants = Restaurant
                  .near(lat, long, distance)
                  .where('is_hidden = false')
                  .where('created_at < ?', Time.at(created_before))

    unless search_text.blank?
      restaurants = restaurants
                    .where('LOWER(name) LIKE ?', "%#{search_text}%")
    end
    unless neighborhood.blank?
      restaurants = restaurants
                    .where('LOWER(neighborhood) LIKE ?', "%#{neighborhood}%")
    end
    unless cuisines.empty?
      restaurants = restaurants
                    .where('cuisines && ARRAY[?]::text[]', cuisines)
    end
    unless price.empty?
      restaurants = restaurants
                    .where('price_band in (?)', price)
    end

    # Prioritize the ones in collections
    # Then sort by distance
    restaurants = restaurants
                  .order("CASE WHEN id IN (SELECT restaurant_id FROM restaurants_users WHERE user_id=#{current_user.id}) THEN 0 ELSE 1 END")
                  .order('distance')

    restaurants = restaurants
                  .offset(offset)

    t1 = Time.now
    # Last index is how many restaurants *that have availabilities* were traversed to fill up to page size
    with_availabilities, last_index = Restaurant.add_availabilities(
      restaurants: restaurants,
      cover: cover,
      datetime: datetime,
      page_size: limit
    )
    t2 = Time.now
    getting_availabilities_time = t2 - t1

    t1 = Time.now
    with_availabilities.each do |r_json|
      restaurant_collections = Collection.get_collections_for_restaurant(restaurant_id: r_json['id'], user_id: current_user.id)
      r_json['collections'] = restaurant_collections.pluck('id, name').map { |id, name| { id: id, name: name } }
    end
    t2 = Time.now
    getting_collections_time = t2 - t1

    logger.debug('Getting availabilities took ' + getting_availabilities_time.to_s + ' seconds')
    logger.debug('Getting restaurants took ' + getting_restaurants_time.to_s + ' seconds')
    logger.debug('Getting collections took ' + getting_collections_time.to_s + ' seconds')

    response = {
      "restaurants": with_availabilities,
      "offset": last_index + offset
    }

    response['initial_query_time'] = created_before if offset == 0

    json_response(response)
  end

  private

  def validate_filter_params
    cover = params[:cover]
    json_response({ error: 'cover not right' }) if cover.to_i.to_s != cover
    if (cover.to_i < 1) || (cover.to_i > 10)
      json_response({ error: 'cover not right' })
    end

    distance = params[:distance]
    if distance.to_f > MAX_SEARCH_DISTANCE
      json_response({ error: 'Search radius too high' })
    end

    offset = params[:offset]
    created_before = params[:created_before]
    if !offset.blank? && created_before.blank?
      json_response({ error: 'Pagination requires both offset and created_before' })
    end
    if offset.blank? && !created_before.blank?
      json_response({ error: 'Pagination requires both offset and created_before' })
    end

    limit = params[:limit]
    json_response({ error: 'Limit too high' }) if limit.to_i > MAX_LIMIT

    unix_datetime = params[:datetime]
    if unix_datetime.to_i.to_s != unix_datetime
      json_response({ error: 'datetime not right' })
    end

    location = params[:location]
    if !location.include?(',') || !location.include?('.')
      json_response({ error: 'location not right' })
    end
  end
end
