# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_14_192041) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "plpgsql"

  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "user_id"], name: "index_name_user_on_collections", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "collections_restaurants", id: false, force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "restaurant_id", null: false
    t.index ["collection_id", "restaurant_id"], name: "index_collections_restaurants", unique: true
    t.index ["collection_id"], name: "index_collections_restaurants_on_collection_id"
    t.index ["restaurant_id"], name: "index_collections_restaurants_on_restaurant_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "user_id"
    t.string "partner"
    t.json "partner_reservation_details"
    t.datetime "reservation_date"
    t.string "confirmation_id"
    t.integer "cover"
    t.boolean "is_past"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_cancelled", default: false
    t.index ["is_cancelled"], name: "index_reservations_on_is_cancelled"
    t.index ["partner"], name: "index_reservations_on_partner"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "restaurant_query_centers", force: :cascade do |t|
    t.decimal "longitude"
    t.decimal "latitude"
    t.datetime "last_query_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "opentable_id"
    t.decimal "longitude"
    t.decimal "latitude"
    t.string "name"
    t.json "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resy_id"
    t.string "yelp_id"
    t.string "tock_id"
    t.integer "price_band"
    t.text "cuisines", array: true
    t.string "neighborhood"
    t.boolean "is_hidden", default: false
    t.index ["is_hidden"], name: "index_restaurants_on_is_hidden"
    t.index ["opentable_id"], name: "index_restaurants_on_opentable_id", unique: true
    t.index ["resy_id"], name: "index_restaurants_on_resy_id", unique: true
    t.index ["tock_id"], name: "index_restaurants_on_tock_id", unique: true
    t.index ["yelp_id"], name: "index_restaurants_on_yelp_id", unique: true
  end

  create_table "restaurants_users", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.bigint "user_id"
    t.index ["restaurant_id"], name: "index_restaurants_users_on_restaurant_id"
    t.index ["user_id"], name: "index_restaurants_users_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.datetime "reset_password_sent_at"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "has_opentable_creds", default: false
    t.json "opentable_auth_data"
    t.json "opentable_user_data"
    t.boolean "has_resy_creds", default: false
    t.json "resy_auth_data"
    t.json "resy_user_data"
    t.boolean "has_yelp_creds", default: false
    t.json "yelp_auth_data"
    t.json "yelp_user_data"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "access_token"
    t.string "number"
    t.boolean "has_tock_creds", default: false
    t.json "tock_auth_data"
    t.json "tock_user_data"
    t.string "partner_auth_salt"
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "collections", "users", on_delete: :cascade
  add_foreign_key "reservations", "users"
  add_foreign_key "restaurants_users", "restaurants"
  add_foreign_key "restaurants_users", "users", on_delete: :cascade
end
