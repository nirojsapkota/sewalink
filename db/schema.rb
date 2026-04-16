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

ActiveRecord::Schema[7.1].define(version: 2026_04_15_133826) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bids", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "message", null: false
    t.integer "status", default: 0, null: false
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "payment_method"
    t.index ["status"], name: "index_bids_on_status"
    t.index ["task_id"], name: "index_bids_on_task_id"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name_en"
    t.string "name_ne"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_en"], name: "index_categories_on_name_en"
    t.index ["name_ne"], name: "index_categories_on_name_ne"
  end

  create_table "double_entry_account_balances", force: :cascade do |t|
    t.string "account", limit: 31, null: false
    t.string "scope", limit: 23
    t.integer "balance", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account"], name: "index_account_balances_on_account"
    t.index ["scope", "account"], name: "index_account_balances_on_scope_and_account", unique: true
  end

  create_table "double_entry_line_aggregates", force: :cascade do |t|
    t.string "function", limit: 15, null: false
    t.string "account", limit: 31, null: false
    t.string "code", limit: 47
    t.string "scope", limit: 23
    t.integer "year"
    t.integer "month"
    t.integer "week"
    t.integer "day"
    t.integer "hour"
    t.integer "amount", null: false
    t.string "filter"
    t.string "range_type", limit: 15, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["function", "account", "code", "year", "month", "week", "day"], name: "line_aggregate_idx"
  end

  create_table "double_entry_line_checks", force: :cascade do |t|
    t.integer "last_line_id", null: false
    t.boolean "errors_found", null: false
    t.text "log"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "double_entry_line_metadata", force: :cascade do |t|
    t.integer "line_id", null: false
    t.string "key", limit: 48, null: false
    t.string "value", limit: 64, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_id", "key", "value"], name: "lines_meta_line_id_key_value_idx"
  end

  create_table "double_entry_lines", force: :cascade do |t|
    t.string "account", limit: 31, null: false
    t.string "scope", limit: 23
    t.string "code", limit: 47, null: false
    t.integer "amount", null: false
    t.integer "balance", null: false
    t.integer "partner_id"
    t.string "partner_account", limit: 31, null: false
    t.string "partner_scope", limit: 23
    t.integer "detail_id"
    t.string "detail_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account", "code", "created_at"], name: "lines_account_code_created_at_idx"
    t.index ["account", "created_at"], name: "lines_account_created_at_idx"
    t.index ["scope", "account", "created_at"], name: "lines_scope_account_created_at_idx"
    t.index ["scope", "account", "id"], name: "lines_scope_account_id_idx"
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.integer "amount_cents"
    t.string "transaction_uuid"
    t.string "status", default: "pending", null: false
    t.string "external_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_payment_transactions_on_task_id"
    t.index ["transaction_uuid"], name: "index_payment_transactions_on_transaction_uuid", unique: true
  end

  create_table "payout_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount_cents"
    t.string "status"
    t.text "payment_details"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_payout_requests_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "location", null: false
    t.float "latitude"
    t.float "longitude"
    t.integer "status", default: 0, null: false
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "budget_cents", default: 0, null: false
    t.integer "payment_type"
    t.index ["category_id"], name: "index_tasks_on_category_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "phone", default: "", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "active_role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "name"
    t.text "bio"
    t.string "locale"
    t.boolean "onboarded", default: false, null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bids", "tasks"
  add_foreign_key "bids", "users"
  add_foreign_key "payment_transactions", "tasks"
  add_foreign_key "payout_requests", "users"
  add_foreign_key "tasks", "categories"
  add_foreign_key "tasks", "users"
end
