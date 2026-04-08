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

ActiveRecord::Schema[8.1].define(version: 2026_04_08_192636) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "entry_type", null: false
    t.bigint "loggable_id", null: false
    t.string "loggable_type", null: false
    t.datetime "occurred_at", null: false
    t.integer "touchpoint_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "canned_responses", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "key"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_canned_responses_on_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["position"], name: "index_canned_responses_on_position"
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

  create_table "conversation_read_states", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id"], name: "index_conversation_read_states_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_conversation_read_states_uniqueness", unique: true
    t.index ["user_id"], name: "index_conversation_read_states_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "assigned_user_id"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.string "external_contact_id", null: false
    t.datetime "last_message_at"
    t.bigint "linkable_id"
    t.string "linkable_type"
    t.integer "platform", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_conversations_on_assigned_user_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["linkable_type", "linkable_id"], name: "index_conversations_on_linkable"
    t.index ["platform", "external_contact_id"], name: "index_conversations_on_platform_and_external_contact_id", unique: true
    t.index ["status"], name: "index_conversations_on_status"
  end

  create_table "customers", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "country"
    t.datetime "created_at", null: false
    t.date "date_became_customer"
    t.string "industry"
    t.date "last_activity_date"
    t.bigint "responsible_consultant_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "strategy"
    t.decimal "total_revenue", precision: 12, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_customers_on_company_name", unique: true
    t.index ["company_name"], name: "index_customers_on_company_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["responsible_consultant_id"], name: "index_customers_on_responsible_consultant_id"
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "deployments", force: :cascade do |t|
    t.string "author"
    t.string "branch"
    t.text "commit_message"
    t.string "commit_sha", null: false
    t.string "commit_url"
    t.datetime "created_at", null: false
    t.datetime "deployed_at", null: false
    t.string "deployed_by"
    t.string "environment"
    t.datetime "updated_at", null: false
    t.string "version"
    t.index ["commit_sha"], name: "index_deployments_on_commit_sha"
    t.index ["deployed_at"], name: "index_deployments_on_deployed_at", unique: true
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

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "direction", null: false
    t.string "external_message_id"
    t.integer "message_type", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.datetime "sent_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["external_message_id"], name: "index_messages_on_external_message_id", unique: true
    t.index ["sent_at"], name: "index_messages_on_sent_at"
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
    t.date "date_asked"
    t.date "date_sent"
    t.text "description", default: "", null: false
    t.decimal "estimated_value", precision: 12, scale: 2
    t.date "expected_close_date"
    t.decimal "final_value", precision: 12, scale: 2
    t.date "last_activity_date"
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
    t.index ["title"], name: "index_proposals_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "prospects", force: :cascade do |t|
    t.string "company_name", null: false
    t.integer "converted_customer_id"
    t.string "country"
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
    t.index ["company_name"], name: "index_prospects_on_company_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["converted_customer_id"], name: "index_prospects_on_converted_customer_id"
    t.index ["primary_contact_email"], name: "index_prospects_on_primary_contact_email", unique: true
    t.index ["responsible_consultant_id"], name: "index_prospects_on_responsible_consultant_id"
    t.index ["status"], name: "index_prospects_on_status"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "consultant_assignments", "users"
  add_foreign_key "contacts", "customers"
  add_foreign_key "conversation_read_states", "conversations"
  add_foreign_key "conversation_read_states", "users"
  add_foreign_key "conversations", "users", column: "assigned_user_id"
  add_foreign_key "customers", "users", column: "responsible_consultant_id"
  add_foreign_key "document_versions", "proposals"
  add_foreign_key "document_versions", "users", column: "archived_by_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "proposals", "users", column: "responsible_consultant_id"
  add_foreign_key "prospects", "users", column: "responsible_consultant_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tasks", "users", column: "assigned_to_id"
end
