class Restaurant < ApplicationRecord
  include RedisLib

  has_and_belongs_to_many :collections

  scope :near, lambda {
    |latitude, longitude, miles|
    select("restaurants.*, point(#{longitude}, #{latitude}) <@> point(longitude, latitude)::point as distance")
      .where("(point(?, ?) <@> point(longitude, latitude)) < ?", longitude, latitude, miles)
  }

  TOP_LEVEL_FIELDS = [
    :id, :name, :longitude, :latitude, :details, :distance, :availabilities, :price_band, :cuisines, :neighborhood
  ]

  Partners = {
    TOCK: 'tock',
    YELP: 'yelp',
    OPENTABLE: 'opentable',
    RESY: 'resy'
  }

  def get_partner_restaurant_id(partner)
      self[Restaurant.get_partner_key_id(partner)]
  end

  def add_details!
    Restaurant::Partners.values.each do |partner|
      if self.has_partner?(partner)
        new_details = get_restaurant_details(
          partner_restaurant_id: self[Restaurant.get_partner_key_id(partner)],
          partner: partner
        )
        self.integrate_new_details!(JSON.parse(new_details))
        break
      end
    end
  end

  def has_details?
    # This is only present in details
    self.details.key?("description")
  end

  def has_partner?(partner)
    !!self.get_partner_restaurant_id(partner)
  end

  def get_cached_availabilities(datetime:, cover:)
    redis_key = "<#{datetime},#{self["id"]},#{cover}>"
    availabilities = $redis.get(redis_key)
    if !availabilities.nil?
      JSON.parse(availabilities)
    else
      nil
    end
  end

  def request_availabilities(datetime:, cover:, restaurant_json:, output_pipe: [])
    redis_key = "<#{datetime},#{self["id"]},#{cover}>"
    Restaurant::Partners.values.each do |partner|
      partner_key_id = Restaurant.get_partner_key_id(partner)
      if !self[partner_key_id].blank?
        # Get the first partner that the restaurant is associated with
        # Potentially could get availabilities from all partners
        request = request_availabilities_from_partner(
          cover: cover,
          partner_restaurant_id: self[partner_key_id],
          datetime: datetime,
          partner: partner
        )
        request.on_complete do |response|
          logger.info("response took " + response.total_time.to_s)
          partner_availabilities = JSON.parse(response.body)
          partner_availabilities["tickets"].each do |partner_a|
            partner_a["partner"] = partner
          end
          partner_availabilities["count"] = partner_availabilities["tickets"].length

          twentyfour_hours_in_seconds = 24*60*60
          three_minutes_in_seconds = 3*60
          # If there aren't *any* availabilities, unlikely that'll change soon
          expiry_seconds = partner_availabilities["count"] == 0 ? twentyfour_hours_in_seconds : three_minutes_in_seconds

          redis_persist(
            key: redis_key,
            value: partner_availabilities.to_json,
            expiry_seconds: expiry_seconds
          )
          restaurant_json['availabilities'] = partner_availabilities
          if partner_availabilities['count'] > 0
            output_pipe.push(restaurant_json)
          end
        end
        return request
      end
    end
    raise "Partner not found"
  end

  class << self
    def get_new_restaurants(cover:, datetime:, latitude:, longitude:)
      partner_restaurants = []

      get_partner_restaurants_batch = Typhoeus::Hydra.hydra
      get_partner_restaurants_requests = []
      Restaurant::Partners.values.each do |partner|
        puts("getting for")
        puts(partner)
        get_partner_restaurants_request = request_new_restaurants(
          lat: latitude,
          long: longitude,
          cover: cover,
          datetime: datetime,
          partner: partner
        )
        get_partner_restaurants_requests.push(get_partner_restaurants_request)
        get_partner_restaurants_batch.queue(get_partner_restaurants_request)
      end
      t1 = Time.now
      get_partner_restaurants_batch.run
      t2 = Time.now
      getting_restaurants_time = t2-t1

      get_partner_restaurants_requests.each do |request|
        partner_restaurants.push(JSON.parse(request.response.body))
      end

      merged_restaurants = merge_partner_restaurants(partner_restaurants)

      restaurants = convert_restaurant_models(merged_restaurants)
      puts("-------------RESTAURANTS-------------------")
      puts(restaurants)

      restaurant_query = RestaurantQueryCenter.find_or_create_by(
        latitude: latitude,
        longitude: longitude,
      )
      # This is the query time, not the reservation time
      restaurant_query.last_query_time = DateTime.now
      begin
        restaurant_query.save
      rescue ActiveRecord::RecordNotUnique
        # There is very small chancne this can run into concurrency issue,
        # but if so, just ignore
      end

      Restaurant.save_restaurant_models(restaurants)
    end

    def add_availabilities(restaurants:, cover:, datetime:, page_size:)
      logger.info("Adding availabilities")
      with_availabilities = []

      get_availabilities_batch = Typhoeus::Hydra.new(:max_concurrency => page_size*2)
      batch_size = 0

      restaurant_index = 0
      restaurants.each do |r|
        r_json = JSON.parse(r.to_json(:only => Restaurant::TOP_LEVEL_FIELDS))
        r_json['original_index'] = restaurant_index
        restaurant_index += 1

        # cached_availabilities = r.get_cached_availabilities(cover: cover, datetime: datetime)
        cached_availabilities = nil
        if !cached_availabilities.nil?
          r_json['availabilities'] = cached_availabilities
          if r_json['availabilities']['count'] > 0
            with_availabilities.push(r_json)
          end
        else
          new_request = r.request_availabilities(cover: cover, datetime: datetime, restaurant_json: r_json, output_pipe: with_availabilities)
          get_availabilities_batch.queue(new_request)
          batch_size += 1
          # A little extra, since parallel requests are cheap but missing enough availabilities is not
          if batch_size == (page_size*2)
            get_availabilities_batch.run
            batch_size = 0
            get_availabilities_batch = Typhoeus::Hydra.new(:max_concurrency => page_size*2)
          end
        end

        if with_availabilities.length >= page_size
          break
        end
      end

      # If there are still ones being batched, this should still be included
      # E.g., assuming restaurants are ranked coming in, if the first one is not cached but the rest are
      # Then we will have culled the most important one if we only included the cached results
      if batch_size > 0
        get_availabilities_batch.run
      end

      with_availabilities.sort_by! { |r| r["original_index"] }
      with_availabilities = with_availabilities.first(page_size)

      if with_availabilities.length > 0
        last_index = with_availabilities.last["original_index"]
      else
        last_index = 0
      end

      with_availabilities.each do |r|
        r.delete("original_index")
      end

      return with_availabilities, last_index
    end

    def get_partner_key_id(partner)
      case partner
      when Partners[:OPENTABLE]
        "opentable_id"
      when Partners[:YELP]
        "yelp_id"
      when Partners[:RESY]
        "resy_id"
      when Partners[:TOCK]
        "tock_id"
      else
        raise "Partner not recognized: #{partner}"
      end
    end

    def get_partner_creds_id(partner)
      case partner
      when Partners[:OPENTABLE]
        "has_opentable_creds"
      when Partners[:YELP]
        "has_yelp_creds"
      when Partners[:RESY]
        "has_resy_creds"
      when Partners[:TOCK]
        "has_tock_creds"
      else
        raise "Partner not recognized: #{partner}"
      end
    end

    def save_restaurant_models(restaurant_models)
      Restaurant.import(restaurant_models, on_duplicate_key_ignore: true)
    end

    private

    def request_new_restaurants(lat:, long:, cover:, datetime:, partner:)
      uri = URI::HTTP.build(host: $loader_host, port: $loader_port, path: "/restaurants/#{lat}/#{long}/#{cover}/#{datetime}/#{partner}")
      Typhoeus::Request.new(uri)
    end

    def distance_close_enough?(lat1:, lat2:, long1:, long2:)
      # https://gizmodo.com/how-precise-is-one-degree-of-longitude-or-latitude-1631241162
      # Roughly 500m of inaccurary
      (lat1-lat2).abs <= 0.005 and (long1-long2).abs <= 0.005
    end

    def name_close_enough?(name1:, name2:)
      cleaned_name1 = name1.gsub(/\W/,'')
      cleaned_name2 = name2.gsub(/\W/,'')

      cleaned_name1.include?(cleaned_name2) or cleaned_name2.include?(cleaned_name1)
    end

    def should_merge(restaurant1, restaurant2)
      is_distance_close_enough = distance_close_enough?(
        lat1: restaurant1["latitude"],
        lat2: restaurant2["latitude"],
        long1: restaurant1["longitude"],
        long2: restaurant2["longitude"],
      )
      is_name_close_enough = name_close_enough?(
        name1: restaurant1["name"],
        name2: restaurant2["name"],
      )

      is_distance_close_enough and is_name_close_enough
    end

    def merge_partner_restaurants(restaurants)
      merged = []
      not_merged = []

      for partner_index in 0..restaurants.length-1
        partner_restaurants = restaurants[partner_index]
        # For every restaurant, compare it to every other restaurant in every other parnter list
        partner_restaurants.each do |partner_restaurant|
          same_restaurants = []
          for other_partner_index in 0..restaurants.length-1
            if partner_index != other_partner_index
              other_partner_restaurants = restaurants[other_partner_index]
              other_partner_restaurants.each do |other_partner_restaurant|
                if should_merge(partner_restaurant, other_partner_restaurant)
                  same_restaurants.push(other_partner_restaurant)
                end
              end
            end
          end
          if same_restaurants.length > 0
            merged.push(merge_restaurants(same_restaurants + [partner_restaurant]))
          else
            not_merged.push(partner_restaurant)
          end
        end
      end

      # logger.info("Original sizes")
      # restaurants.each do |partner_restaurants|
      #   logger.info(partner_restaurants.length)
      # end
      #
      # logger.info("Merged size")
      # logger.info(merged.length)
      # logger.info(merged.uniq.length)
      #
      # logger.info("Unmerged size")
      # logger.info(not_merged.length)
      # logger.info(not_merged.uniq.length)

      merged.uniq + not_merged.uniq
    end

    def merge_restaurants(restaurants)
      merged_restaurant = {}

      restaurants.each do |r|
        r.each do |k, v|
          if !merged_restaurant.key?(k)
            merged_restaurant[k] = v
          end
        end
      end

      merged_restaurant
    end

    def convert_restaurant_models(restaurants)
      top_level_fields = ["opentableId", "yelpId", "resyId", "tockId", "longitude", "latitude", "name", "priceBand", "cuisines", "neighborhood"]
      restaurant_models = []
      restaurants.each do |r|
        r_details = {}

        r.each do |key, value|
          if !top_level_fields.include? key
            r_details[key] = value
          end
        end
        new = Restaurant.new(
          :opentable_id => r["opentableId"],
          :yelp_id => r["yelpId"],
          :tock_id => r["tockId"],
          :resy_id => r["resyId"],
          :longitude => r["longitude"],
          :latitude => r["latitude"],
          :name => r["name"],
          :price_band => r["priceBand"],
          :cuisines => r["cuisines"],
          :neighborhood => r["neighborhood"],
          :details => r_details
        )
        restaurant_models.push(new)
      end

      restaurant_models
    end
  end

  def request_availabilities_from_partner(cover:, partner_restaurant_id:, datetime:, partner:)
    uri = URI::HTTP.build(host: $loader_host, port: $loader_port, path: "/availabilities/#{cover}/#{partner_restaurant_id}/#{datetime}/#{partner}")
    Typhoeus::Request.new(uri)
  end

  def get_restaurant_details(partner_restaurant_id:, partner:)
    response = Net::HTTP.get_response($loader_host, "restaurants/#{partner_restaurant_id}/#{partner}", $loader_port)

    response.body
  end

  def integrate_new_details!(details)
    current_details = self.details
    details.each do |k, v|
      current_details[k] = v
    end

    self.details = current_details
    self.save!
  end
end
