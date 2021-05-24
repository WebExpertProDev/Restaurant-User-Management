class RestaurantWriter
  include Sidekiq::Worker

  def perform(thing)
    logger.info("savivng")
  end
end
