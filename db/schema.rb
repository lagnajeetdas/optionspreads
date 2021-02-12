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

ActiveRecord::Schema.define(version: 2021_02_12_202417) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "expirycalendars", force: :cascade do |t|
    t.string "year"
    t.string "expiry_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "optionbookmarks", force: :cascade do |t|
    t.string "longleg"
    t.string "shortleg"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "underlying"
    t.string "e_date"
    t.index ["user_id"], name: "index_optionbookmarks_on_user_id"
  end

  create_table "optionchains", force: :cascade do |t|
    t.integer "universe_id"
    t.string "symbol"
    t.text "description"
    t.string "exch"
    t.string "option_type"
    t.float "volume"
    t.float "bid"
    t.float "ask"
    t.string "underlying"
    t.float "strike"
    t.float "change_percentage"
    t.float "average_volume"
    t.float "last_volume"
    t.float "bidsize"
    t.float "asksize"
    t.float "open_interest"
    t.float "contract_size"
    t.string "expiration_date"
    t.string "expiration_type"
    t.string "root_symbol"
    t.float "bid_iv"
    t.float "mid_iv"
    t.float "ask_iv"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "quote"
    t.index ["universe_id"], name: "index_optionchains_on_universe_id"
  end

  create_table "optiondownloadlogs", force: :cascade do |t|
    t.string "activity"
    t.datetime "execution_time"
    t.integer "count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "function_name"
  end

  create_table "optionhighopeninterests", force: :cascade do |t|
    t.string "underlying"
    t.string "expiration_date"
    t.float "strike"
    t.float "bid"
    t.float "ask"
    t.float "last_volume"
    t.float "open_interest"
    t.string "symbol"
    t.float "quote"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "option_type"
  end

  create_table "optionscenarios", force: :cascade do |t|
    t.string "underlying"
    t.string "expiry_date"
    t.float "buy_strike"
    t.float "sell_strike"
    t.float "risk"
    t.float "reward"
    t.float "rr_ratio"
    t.float "perc_change"
    t.string "buy_contract_symbol"
    t.string "sell_contract_symbol"
    t.float "buy_contract_iv"
    t.float "sell_contract_iv"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "strategy"
    t.float "quote"
  end

  create_table "recommendations", force: :cascade do |t|
    t.float "buy"
    t.float "hold"
    t.string "period"
    t.float "sell"
    t.float "strongbuy"
    t.float "strongsell"
    t.string "symbol"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "stockprices", force: :cascade do |t|
    t.string "symbol"
    t.float "last"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "stockprofiles", force: :cascade do |t|
    t.string "symbol"
    t.text "logo"
    t.string "industry"
    t.float "marketcap"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "marketcap_type"
    t.string "belongsto_index"
    t.float "target_price"
    t.string "next_earnings_date"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "ticker"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "target_price_auto"
    t.float "target_price_manual"
    t.index ["user_id"], name: "index_stocks_on_user_id"
  end

  create_table "topoptionscenarios", force: :cascade do |t|
    t.string "underlying"
    t.string "expiry_date"
    t.float "buy_strike"
    t.float "sell_strike"
    t.float "risk"
    t.float "reward"
    t.float "rr_ratio"
    t.float "perc_change"
    t.string "buy_contract_symbol"
    t.string "sell_contract_symbol"
    t.float "buy_contract_iv"
    t.float "sell_contract_iv"
    t.float "stock_quote"
    t.string "stock_description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "industry"
  end

  create_table "universes", force: :cascade do |t|
    t.string "currency"
    t.text "description"
    t.string "displaysymbol"
    t.text "figi"
    t.string "mic"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "security_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "optionchains", "universes"
end
