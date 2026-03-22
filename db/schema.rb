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

ActiveRecord::Schema[8.1].define(version: 2026_03_22_204050) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "entry_type", null: false
    t.bigint "loggable_id", null: false
    t.string "loggable_type", null: false
    t.integer "touchpoint_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "consultant_assignments", force: :cascade do |t|
    t.bigint "assignable_id", null: false
    t.string "assignable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["assignable_type", "assignable_id"], name: "index_consultant_assignments_on_assignable"
    t.index ["user_id", "assignable_type", "assignable_id"], name: "idx_consultant_assignments_uniqueness", unique: true
    t.index ["user_id"], name: "index_consultant_assignments_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.boolean "primary", default: false, null: false
    t.string "role_title"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_contacts_on_customer_id"
    t.index ["email"], name: "index_contacts_on_email"
  end

  create_table "customers", force: :cascade do |t|
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.date "date_became_customer", null: false
    t.string "industry"
    t.date "last_activity_date", null: false
    t.bigint "responsible_consultant_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_revenue", precision: 12, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_customers_on_company_name", unique: true
    t.index ["responsible_consultant_id"], name: "index_customers_on_responsible_consultant_id"
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "document_versions", force: :cascade do |t|
    t.datetime "archived_at", null: false
    t.bigint "archived_by_id", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.bigint "proposal_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["archived_by_id"], name: "index_document_versions_on_archived_by_id"
    t.index ["proposal_id"], name: "index_document_versions_on_proposal_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "notification_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "notification_type"], name: "idx_on_user_id_notification_type_2ab4363e9b", unique: true
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.date "actual_close_date"
    t.datetime "created_at", null: false
    t.string "current_document_url"
    t.date "date_sent"
    t.decimal "estimated_value", precision: 12, scale: 2
    t.date "expected_close_date"
    t.decimal "final_value", precision: 12, scale: 2
    t.bigint "linkable_id", null: false
    t.string "linkable_type", null: false
    t.text "notes"
    t.bigint "responsible_consultant_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.text "win_loss_reason"
    t.index ["expected_close_date"], name: "index_proposals_on_expected_close_date"
    t.index ["linkable_type", "linkable_id"], name: "index_proposals_on_linkable"
    t.index ["responsible_consultant_id"], name: "index_proposals_on_responsible_consultant_id"
    t.index ["status"], name: "index_proposals_on_status"
  end

  create_table "prospects", force: :cascade do |t|
    t.string "company_name", null: false
    t.integer "converted_customer_id"
    t.datetime "created_at", null: false
    t.date "date_added", null: false
    t.text "disqualification_reason"
    t.decimal "estimated_value", precision: 12, scale: 2
    t.string "industry"
    t.date "last_activity_date", null: false
    t.string "primary_contact_email", null: false
    t.string "primary_contact_name", null: false
    t.string "primary_contact_phone"
    t.bigint "responsible_consultant_id", null: false
    t.integer "source"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_prospects_on_company_name", unique: true
    t.index ["converted_customer_id"], name: "index_prospects_on_converted_customer_id"
    t.index ["primary_contact_email"], name: "index_prospects_on_primary_contact_email", unique: true
    t.index ["responsible_consultant_id"], name: "index_prospects_on_responsible_consultant_id"
    t.index ["status"], name: "index_prospects_on_status"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assigned_to_id", null: false
    t.text "cancellation_reason"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.bigint "linkable_id", null: false
    t.string "linkable_type", null: false
    t.text "notes"
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_tasks_on_assigned_to_id"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["linkable_type", "linkable_id"], name: "index_tasks_on_linkable"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["status"], name: "index_tasks_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid"
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "consultant_assignments", "users"
  add_foreign_key "contacts", "customers"
  add_foreign_key "customers", "users", column: "responsible_consultant_id"
  add_foreign_key "document_versions", "proposals"
  add_foreign_key "document_versions", "users", column: "archived_by_id"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "proposals", "users", column: "responsible_consultant_id"
  add_foreign_key "prospects", "users", column: "responsible_consultant_id"
  add_foreign_key "tasks", "users", column: "assigned_to_id"
end
