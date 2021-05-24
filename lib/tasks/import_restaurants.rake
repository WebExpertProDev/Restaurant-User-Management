namespace :restaurants do
  desc "Restaurant tasks"

  task :import_from_json => :environment do
    restaurants = JSON.parse(File.read('restaurants.json'))

    restaurants.each do |r|
      r_details = {}

      top_level_fields = ["opentableId", "longitude", "latitude", "name"]
      r.each do |key, value|
        if !top_level_fields.include? key
          r_details[key] = value
        end
      end
      new = Restaurant.new(
        :opentable_id => r["opentableId"],
        :longitude => r["longitude"],
        :latitude => r["latitude"],
        :name => r["name"],
        :details => r_details
        )
      new.save!
    end
  end

  task :test_uniqueness => :environment do
    new = Restaurant.new(
      :opentable_id => "123",
      )
    new.save!
    new1 = Restaurant.new(
      :opentable_id => "123",
      )
    begin
      new1.save!
    rescue ActiveRecord::RecordNotUnique => e
    end
  end
end
