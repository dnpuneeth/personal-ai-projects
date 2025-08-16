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

ActiveRecord::Schema[8.0].define(version: 2025_08_16_035714) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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

  create_table "ai_events", force: :cascade do |t|
    t.bigint "document_id"
    t.string "event_type"
    t.string "model"
    t.integer "tokens_used"
    t.integer "latency_ms"
    t.integer "cost_cents"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "deleted_document_id"
    t.index ["deleted_document_id"], name: "index_ai_events_on_deleted_document_id"
    t.index ["document_id"], name: "index_ai_events_on_document_id"
  end

  create_table "deleted_documents", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "original_document_id", null: false
    t.string "title", null: false
    t.string "file_type"
    t.integer "page_count", default: 0
    t.integer "chunk_count", default: 0
    t.integer "total_cost_cents", default: 0
    t.integer "total_tokens_used", default: 0
    t.integer "ai_events_count", default: 0
    t.datetime "deleted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_deleted_documents_on_deleted_at"
    t.index ["original_document_id"], name: "index_deleted_documents_on_original_document_id"
    t.index ["user_id"], name: "index_deleted_documents_on_user_id"
  end

# Could not dump table "doc_chunks" because of following StandardError
#   Unknown type 'vector(1536)' for column 'embedding'


  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.string "status"
    t.integer "page_count"
    t.integer "chunk_count"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "temp_ai_results", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "event_type", null: false
    t.json "result_data", null: false
    t.boolean "cached", default: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "event_type"], name: "index_temp_ai_results_on_document_id_and_event_type"
    t.index ["document_id"], name: "index_temp_ai_results_on_document_id"
    t.index ["expires_at"], name: "index_temp_ai_results_on_expires_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "avatar_url"
    t.integer "documents_uploaded", default: 0, null: false
    t.integer "ai_actions_used", default: 0, null: false
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_id", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_events", "deleted_documents"
  add_foreign_key "ai_events", "documents"
  add_foreign_key "deleted_documents", "users"
  add_foreign_key "doc_chunks", "documents"
  add_foreign_key "documents", "users"
  add_foreign_key "temp_ai_results", "documents"
end
