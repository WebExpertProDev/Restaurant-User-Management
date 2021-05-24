module RedisLib
  def redis_persist(key:, value:, expiry_seconds:)
    # Set and expire, in seconds
    $redis.setex(key, expiry_seconds, value)
  end
end
