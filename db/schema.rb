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

ActiveRecord::Schema[8.1].define(version: 2026_05_02_210317) do
  create_table "api_keys", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "bearer_id", null: false
    t.string "bearer_type", null: false
    t.datetime "created_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["bearer_id", "bearer_type"], name: "index_api_keys_on_bearer_id_and_bearer_type"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "cases", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "byear"
    t.boolean "chat_active"
    t.string "country"
    t.datetime "created_at", null: false
    t.integer "dyear"
    t.string "external_id"
    t.boolean "nodelete"
    t.integer "sex"
    t.datetime "updated_at", null: false
  end

  create_table "checklists", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.datetime "created_at", null: false
    t.string "flow_ref"
    t.bigint "planitem_id"
    t.integer "status", default: 1, null: false
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_checklists_on_case_id"
    t.index ["planitem_id"], name: "index_checklists_on_planitem_id"
  end

  create_table "cslices", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "case_id"
    t.datetime "created_at", null: false
    t.integer "cvaluetype"
    t.string "disclaimer"
    t.decimal "i", precision: 6, scale: 4
    t.string "info"
    t.string "label"
    t.integer "planitem_id"
    t.string "source"
    t.integer "t"
    t.datetime "updated_at", null: false
    t.index ["planitem_id"], name: "index_cslices_on_planitem_id"
  end

  create_table "cvalues", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "case_id"
    t.integer "cf_type"
    t.datetime "created_at", null: false
    t.integer "cslice_id"
    t.decimal "cto", precision: 14, scale: 2
    t.integer "cvaluetype"
    t.decimal "ev", precision: 14, scale: 2
    t.integer "fromt"
    t.decimal "inflation", precision: 6, scale: 4
    t.decimal "interest", precision: 6, scale: 4
    t.string "label"
    t.integer "planitem_id"
    t.integer "t"
    t.integer "tot"
    t.datetime "updated_at", null: false
    t.index ["planitem_id"], name: "index_cvalues_on_planitem_id"
  end

  create_table "pensionfactors", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "factor"
    t.string "provider"
    t.string "ptype"
    t.string "subgroup"
    t.decimal "value", precision: 10, scale: 2
    t.integer "year"
  end

  create_table "persistaccounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "lastaction"
    t.string "password_digest"
    t.string "randname", null: false
    t.datetime "updated_at", null: false
    t.index ["randname"], name: "index_persistaccounts_on_randname", unique: true
  end

  create_table "planitems", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.integer "category"
    t.datetime "created_at", null: false
    t.integer "fromt"
    t.integer "leadt"
    t.integer "months"
    t.integer "plan_type"
    t.string "title"
    t.integer "tot"
    t.integer "trailt"
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_planitems_on_case_id"
  end

  create_table "simulations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "case_id"
    t.datetime "created_at", null: false
    t.integer "sourceid"
    t.integer "sourcetype"
    t.integer "t"
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 14, scale: 2
    t.integer "valuetype"
  end

  add_foreign_key "checklists", "cases"
  add_foreign_key "checklists", "planitems"
  add_foreign_key "planitems", "cases"
end
