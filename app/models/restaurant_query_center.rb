class RestaurantQueryCenter < ApplicationRecord
  # The maximum distance between queries. 
  # If a potential query is more than this for all the queries in the DB,
  # it should go through
  THRESHOLD_DISTANCE_MILES = 5

  # The maximum days between queries that are less than THRESHOLD_DISTANCE_MILES apart
  # If a potential query is more than this for all the queries in the DB,
  # it should go through
  THRESHOLD_DAYS = 5

  class << self
    def should_query(latitude:, longitude:, datetime:)
      # Find a result that
      # - distance between it and the given is less than threshold distance
      # and
      # - days between that query and now is less than threshold days
      result = RestaurantQueryCenter
        .where("(point(?, ?) <@> point(longitude, latitude)) < ?", longitude, latitude, THRESHOLD_DISTANCE_MILES)
        .where("DATE_PART('day', age(?::timestamp, last_query_time)) < ?", datetime, THRESHOLD_DAYS)
        .take(1)

      result.length == 0
    end
  end
end
