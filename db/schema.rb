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

ActiveRecord::Schema[8.1].define(version: 2026_07_09_075924) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "monthly_entries", force: :cascade do |t|
    t.decimal "actual_variation_pct", precision: 8, scale: 4
    t.decimal "benchmark_variation_pct", precision: 8, scale: 4, null: false
    t.decimal "contribution_amount", precision: 14, scale: 2
    t.datetime "created_at", null: false
    t.decimal "cumulative_capital", precision: 14, scale: 2
    t.decimal "cumulative_contribution", precision: 14, scale: 2
    t.decimal "delta", precision: 14, scale: 2
    t.date "month", null: false
    t.text "notes"
    t.decimal "planned_contribution_amount", precision: 14, scale: 2, null: false
    t.bigint "position_id", null: false
    t.datetime "updated_at", null: false
    t.index ["position_id", "month"], name: "index_monthly_entries_on_position_id_and_month", unique: true
    t.index ["position_id"], name: "index_monthly_entries_on_position_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "account_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.date "opening_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "asset_class", null: false
    t.string "asset_name", null: false
    t.string "benchmark_name", null: false
    t.datetime "created_at", null: false
    t.decimal "initial_capital", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "initial_contribution", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "portfolio_id", null: false
    t.decimal "ter_pct", precision: 5, scale: 2
    t.string "ticker"
    t.datetime "updated_at", null: false
    t.index ["portfolio_id"], name: "index_positions_on_portfolio_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "monthly_entries", "positions"
  add_foreign_key "portfolios", "users"
  add_foreign_key "positions", "portfolios"
end
