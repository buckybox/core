# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120820040446) do

  create_table "accounts", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "balance_cents", :default => 0, :null => false
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["customer_id"], :name => "index_accounts_on_customer_id"

  create_table "addresses", :force => true do |t|
    t.integer  "customer_id"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "suburb"
    t.string   "city"
    t.string   "postcode"
    t.text     "delivery_note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone_1"
    t.string   "phone_2"
    t.string   "phone_3"
    t.string   "address_hash"
  end

  add_index "addresses", ["address_hash"], :name => "index_addresses_on_address_hash"
  add_index "addresses", ["customer_id"], :name => "index_addresses_on_customer_id"

  create_table "admins", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  add_index "admins", ["email"], :name => "index_admins_on_email", :unique => true
  add_index "admins", ["reset_password_token"], :name => "index_admins_on_reset_password_token", :unique => true

  create_table "bank_information", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "name"
    t.string   "account_name"
    t.string   "account_number"
    t.text     "customer_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bank_information", ["distributor_id"], :name => "index_bank_information_on_distributor_id"

  create_table "bank_statements", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "statement_file"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "bank_statements", ["distributor_id"], :name => "index_bank_statements_on_distributor_id"

  create_table "box_extras", :force => true do |t|
    t.integer  "box_id"
    t.integer  "extra_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "boxes", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "name"
    t.text     "description"
    t.boolean  "likes",                  :default => false, :null => false
    t.boolean  "dislikes",               :default => false, :null => false
    t.integer  "price_cents",            :default => 0,     :null => false
    t.string   "currency"
    t.boolean  "available_single",       :default => false, :null => false
    t.boolean  "available_weekly",       :default => false, :null => false
    t.boolean  "available_fourtnightly", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "box_image"
    t.boolean  "available_monthly",      :default => false, :null => false
    t.integer  "extras_limit",           :default => 0
  end

  add_index "boxes", ["distributor_id"], :name => "index_boxes_on_distributor_id"

  create_table "cron_logs", :force => true do |t|
    t.text     "log"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "details"
  end

  create_table "customers", :force => true do |t|
    t.string   "first_name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "last_name"
    t.integer  "distributor_id"
    t.integer  "route_id"
    t.string   "encrypted_password",       :limit => 128, :default => "",  :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                         :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.decimal  "discount",                                :default => 0.0, :null => false
    t.integer  "number"
    t.text     "notes"
    t.text     "special_order_preference"
  end

  add_index "customers", ["authentication_token"], :name => "index_customers_on_authentication_token", :unique => true
  add_index "customers", ["confirmation_token"], :name => "index_customers_on_confirmation_token", :unique => true
  add_index "customers", ["email"], :name => "index_customers_on_email", :unique => true
  add_index "customers", ["reset_password_token"], :name => "index_customers_on_reset_password_token", :unique => true
  add_index "customers", ["route_id"], :name => "index_customers_on_route_id"
  add_index "customers", ["unlock_token"], :name => "index_customers_on_unlock_token", :unique => true

  create_table "deductions", :force => true do |t|
    t.integer  "distributor_id"
    t.integer  "account_id",              :default => 0, :null => false
    t.integer  "amount_cents",            :default => 0, :null => false
    t.string   "currency"
    t.string   "kind"
    t.text     "description"
    t.boolean  "reversed"
    t.datetime "reversed_at"
    t.integer  "transaction_id"
    t.integer  "reversal_transaction_id"
    t.string   "source"
    t.integer  "deductable_id"
    t.string   "deductable_type"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.datetime "display_time"
  end

  add_index "deductions", ["account_id"], :name => "index_deductions_on_account_id"
  add_index "deductions", ["distributor_id"], :name => "index_deductions_on_distributor_id"

  create_table "deliveries", :force => true do |t|
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "route_id"
    t.string   "status_change_type"
    t.integer  "delivery_list_id"
    t.integer  "position"
    t.integer  "package_id"
    t.integer  "delivery_number"
    t.integer  "dso",                :default => -1
  end

  add_index "deliveries", ["delivery_list_id"], :name => "index_deliveries_on_delivery_list_id"
  add_index "deliveries", ["package_id"], :name => "index_deliveries_on_package_id"
  add_index "deliveries", ["route_id"], :name => "index_deliveries_on_route_id"

  create_table "delivery_lists", :force => true do |t|
    t.integer  "distributor_id"
    t.date     "date"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "delivery_lists", ["distributor_id"], :name => "index_delivery_lists_on_distributor_id"

  create_table "delivery_sequence_orders", :force => true do |t|
    t.string   "address_hash"
    t.integer  "route_id"
    t.integer  "day"
    t.integer  "position"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "distributors", :force => true do |t|
    t.string   "email",                                  :default => "",    :null => false
    t.string   "encrypted_password",      :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "url"
    t.string   "company_logo"
    t.boolean  "completed_wizard",                       :default => false, :null => false
    t.string   "parameter_name"
    t.integer  "invoice_threshold_cents",                :default => 0,     :null => false
    t.decimal  "bucky_box_percentage",                                      :null => false
    t.boolean  "separate_bucky_fee",                     :default => true
    t.string   "support_email"
    t.string   "time_zone"
    t.integer  "advance_hour"
    t.integer  "advance_days"
    t.integer  "automatic_delivery_hour"
    t.string   "currency"
    t.boolean  "bank_deposit"
    t.boolean  "paypal"
    t.string   "bank_deposit_format"
  end

  add_index "distributors", ["authentication_token"], :name => "index_distributors_on_authentication_token", :unique => true
  add_index "distributors", ["confirmation_token"], :name => "index_distributors_on_confirmation_token", :unique => true
  add_index "distributors", ["email"], :name => "index_distributors_on_email", :unique => true
  add_index "distributors", ["reset_password_token"], :name => "index_distributors_on_reset_password_token", :unique => true
  add_index "distributors", ["unlock_token"], :name => "index_distributors_on_unlock_token", :unique => true

  create_table "events", :force => true do |t|
    t.integer  "distributor_id",                       :null => false
    t.string   "event_category",                       :null => false
    t.string   "event_type",                           :null => false
    t.integer  "customer_id"
    t.integer  "invoice_id"
    t.integer  "reconciliation_id"
    t.integer  "transaction_id"
    t.integer  "delivery_id"
    t.boolean  "dismissed",         :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "trigger_on"
  end

  add_index "events", ["distributor_id"], :name => "index_events_on_distributor_id"

  create_table "exclusions", :force => true do |t|
    t.integer  "order_id"
    t.integer  "line_item_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "exclusions", ["line_item_id"], :name => "index_exclusions_on_line_item_id"
  add_index "exclusions", ["order_id"], :name => "index_exclusions_on_order_id"

  create_table "extras", :force => true do |t|
    t.string   "name"
    t.string   "unit"
    t.integer  "distributor_id"
    t.integer  "price_cents",    :default => 0, :null => false
    t.string   "currency"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "import_transaction_lists", :force => true do |t|
    t.integer  "distributor_id"
    t.boolean  "draft"
    t.integer  "account_type"
    t.string   "csv_file"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "file_format"
  end

  add_index "import_transaction_lists", ["distributor_id", "draft"], :name => "index_import_transaction_lists_on_distributor_id_and_draft"

  create_table "import_transactions", :force => true do |t|
    t.integer  "customer_id"
    t.date     "transaction_date"
    t.integer  "amount_cents",               :default => 0, :null => false
    t.boolean  "removed"
    t.text     "description"
    t.float    "confidence"
    t.integer  "import_transaction_list_id"
    t.integer  "match"
    t.integer  "transaction_id"
    t.boolean  "draft"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "payment_id"
    t.text     "raw_data"
  end

  add_index "import_transactions", ["import_transaction_list_id", "draft"], :name => "index_import_draft"
  add_index "import_transactions", ["import_transaction_list_id", "match"], :name => "index_import_match"
  add_index "import_transactions", ["import_transaction_list_id", "removed"], :name => "index_import_removed"
  add_index "import_transactions", ["import_transaction_list_id"], :name => "index_import_transactions_on_import_transaction_list_id"

  create_table "invoice_information", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "gst_number"
    t.string   "billing_address_1"
    t.string   "billing_address_2"
    t.string   "billing_suburb"
    t.string   "billing_city"
    t.string   "billing_postcode"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
  end

  add_index "invoice_information", ["distributor_id"], :name => "index_invoice_information_on_distributor_id"

  create_table "invoices", :force => true do |t|
    t.integer  "account_id"
    t.integer  "number"
    t.integer  "amount_cents",  :default => 0,     :null => false
    t.integer  "balance_cents", :default => 0,     :null => false
    t.string   "currency"
    t.date     "date"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "transactions"
    t.text     "deliveries"
    t.boolean  "paid",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "line_items", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "name"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "line_items", ["distributor_id"], :name => "index_line_items_on_distributor_id"

  create_table "order_extras", :force => true do |t|
    t.integer  "order_id"
    t.integer  "extra_id"
    t.integer  "count"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "order_schedule_transactions", :force => true do |t|
    t.integer  "order_id"
    t.text     "schedule"
    t.integer  "delivery_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_schedule_transactions", ["delivery_id"], :name => "index_order_schedule_transactions_on_delivery_id"
  add_index "order_schedule_transactions", ["order_id"], :name => "index_order_schedule_transactions_on_order_id"

  create_table "orders", :force => true do |t|
    t.integer  "box_id"
    t.integer  "quantity",       :default => 1,        :null => false
    t.string   "frequency",      :default => "single", :null => false
    t.boolean  "completed",      :default => false,    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
    t.text     "schedule"
    t.boolean  "active",         :default => false,    :null => false
    t.boolean  "extras_one_off", :default => true
  end

  add_index "orders", ["account_id"], :name => "index_orders_on_account_id"
  add_index "orders", ["box_id"], :name => "index_orders_on_box_id"

  create_table "packages", :force => true do |t|
    t.integer  "packing_list_id"
    t.integer  "position"
    t.string   "status"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "order_id"
    t.integer  "original_package_id"
    t.string   "packing_method"
    t.text     "archived_address"
    t.integer  "archived_order_quantity"
    t.string   "archived_box_name"
    t.integer  "archived_box_price_cents",   :default => 0,   :null => false
    t.string   "currency"
    t.string   "archived_customer_name"
    t.integer  "archived_route_fee_cents",   :default => 0,   :null => false
    t.decimal  "archived_customer_discount", :default => 0.0, :null => false
    t.text     "archived_extras"
  end

  add_index "packages", ["order_id"], :name => "index_packages_on_order_id"
  add_index "packages", ["original_package_id"], :name => "index_packages_on_original_package_id"
  add_index "packages", ["packing_list_id"], :name => "index_packages_on_packing_list_id"

  create_table "packing_lists", :force => true do |t|
    t.integer  "distributor_id"
    t.date     "date"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "packing_lists", ["distributor_id"], :name => "index_packing_lists_on_distributor_id"

  create_table "payments", :force => true do |t|
    t.integer  "distributor_id"
    t.integer  "account_id"
    t.integer  "amount_cents",            :default => 0, :null => false
    t.string   "currency"
    t.string   "kind"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reference"
    t.boolean  "reversed"
    t.datetime "reversed_at"
    t.integer  "transaction_id"
    t.integer  "reversal_transaction_id"
    t.string   "source"
    t.datetime "display_time"
    t.integer  "payable_id"
    t.string   "payable_type"
  end

  add_index "payments", ["account_id"], :name => "index_payments_on_account_id"
  add_index "payments", ["distributor_id"], :name => "index_payments_on_distributor_id"

  create_table "route_schedule_transactions", :force => true do |t|
    t.integer  "route_id"
    t.text     "schedule"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "route_schedule_transactions", ["route_id"], :name => "index_route_schedule_transactions_on_route_id"

  create_table "routes", :force => true do |t|
    t.integer  "distributor_id"
    t.string   "name"
    t.boolean  "monday",         :default => false, :null => false
    t.boolean  "tuesday",        :default => false, :null => false
    t.boolean  "wednesday",      :default => false, :null => false
    t.boolean  "thursday",       :default => false, :null => false
    t.boolean  "friday",         :default => false, :null => false
    t.boolean  "saturday",       :default => false, :null => false
    t.boolean  "sunday",         :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "schedule"
    t.integer  "fee_cents",      :default => 0,     :null => false
    t.string   "currency"
  end

  add_index "routes", ["distributor_id"], :name => "index_routes_on_distributor_id"

  create_table "schedule_rules", :force => true do |t|
    t.string   "time_zone"
    t.string   "recur"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "month_day"
    t.boolean  "mon"
    t.boolean  "tue"
    t.boolean  "wed"
    t.boolean  "thu"
    t.boolean  "fri"
    t.boolean  "sat"
    t.boolean  "sun"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "substitutions", :force => true do |t|
    t.integer  "order_id"
    t.integer  "line_item_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "substitutions", ["line_item_id"], :name => "index_substitutions_on_line_item_id"
  add_index "substitutions", ["order_id"], :name => "index_substitutions_on_order_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "transactions", :force => true do |t|
    t.integer  "account_id"
    t.integer  "amount_cents",         :default => 0, :null => false
    t.string   "currency"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "display_time"
    t.integer  "transactionable_id"
    t.string   "transactionable_type"
  end

  add_index "transactions", ["account_id"], :name => "index_transactions_on_account_id"

end
