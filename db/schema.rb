# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_06_19_213509) do
  create_table "api_keys", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "bearer_id", null: false
    t.string "bearer_type", null: false
    t.string "token_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bearer_id", "bearer_type"], name: "index_api_keys_on_bearer_id_and_bearer_type"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "cases", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "external_id"
    t.integer "byear"
    t.integer "dyear"
    t.integer "sex"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cslices", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cvaluetype"
    t.string "label"
    t.integer "case_id"
    t.integer "t"
    t.decimal "i", precision: 6, scale: 4
    t.string "disclaimer"
    t.string "source"
    t.string "info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cvalues", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "case_id"
    t.integer "cslice_id"
    t.integer "t"
    t.integer "cvaluetype"
    t.string "label"
    t.decimal "cto", precision: 14, scale: 2
    t.decimal "ev", precision: 14, scale: 2
    t.integer "fromt"
    t.integer "tot"
    t.decimal "interest", precision: 6, scale: 4
    t.decimal "inflation", precision: 6, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "persistaccounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "randname", null: false
    t.string "password_digest"
    t.date "lastaction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["randname"], name: "index_persistaccounts_on_randname", unique: true
  end

  create_table "simulations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "case_id"
    t.integer "valuetype"
    t.integer "sourcetype"
    t.integer "sourceid"
    t.integer "t"
    t.decimal "value", precision: 14, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
