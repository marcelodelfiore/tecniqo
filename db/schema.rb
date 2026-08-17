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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_010100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_performeds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "recorded_at", "id"], name: "index_action_performeds_on_chronology"
    t.index ["execution_id"], name: "index_action_performeds_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_action_performeds_on_id_execution_and_org", unique: true
    t.index ["organization_id"], name: "index_action_performeds_on_organization_id"
    t.index ["recorded_by_membership_id", "organization_id"], name: "index_action_performeds_on_recorder_and_org"
    t.index ["recorded_by_membership_id"], name: "index_action_performeds_on_recorded_by_membership_id"
    t.check_constraint "btrim(description) <> ''::text", name: "action_performeds_description_present"
  end

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

  create_table "assets", force: :cascade do |t|
    t.string "asset_type", default: "other", null: false
    t.datetime "created_at", null: false
    t.string "manufacturer"
    t.string "model"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "serial_number"
    t.bigint "site_id", null: false
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["id", "site_id", "organization_id"], name: "index_assets_on_id_and_site_id_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_assets_on_organization_id"
    t.index ["site_id", "organization_id"], name: "index_assets_on_site_id_and_organization_id"
    t.index ["site_id"], name: "index_assets_on_site_id"
    t.check_constraint "asset_type::text = ANY (ARRAY['motor'::character varying, 'electrical_panel'::character varying, 'transformer'::character varying, 'generator'::character varying, 'vfd'::character varying, 'ups'::character varying, 'spda'::character varying, 'capacitor_bank'::character varying, 'other'::character varying]::text[])", name: "assets_asset_type_check"
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "assigned_at", null: false
    t.bigint "assigned_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.bigint "membership_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["assigned_by_id"], name: "index_assignments_on_assigned_by_id"
    t.index ["membership_id", "organization_id"], name: "index_assignments_on_membership_id_and_organization_id"
    t.index ["membership_id"], name: "index_assignments_on_membership_id"
    t.index ["organization_id"], name: "index_assignments_on_organization_id"
    t.index ["work_order_id", "organization_id"], name: "index_assignments_on_work_order_id_and_organization_id"
    t.index ["work_order_id"], name: "index_assignments_on_current_work_order", unique: true, where: "(ended_at IS NULL)"
    t.index ["work_order_id"], name: "index_assignments_on_work_order_id"
    t.check_constraint "ended_at IS NULL OR ended_at >= assigned_at", name: "assignments_timeline_check"
  end

  create_table "clarification_evidences", force: :cascade do |t|
    t.bigint "clarification_request_id", null: false
    t.datetime "created_at", null: false
    t.bigint "evidence_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["clarification_request_id", "evidence_id"], name: "index_clarification_evidences_on_request_and_evidence", unique: true
    t.index ["clarification_request_id"], name: "index_clarification_evidences_on_clarification_request_id"
    t.index ["evidence_id"], name: "index_clarification_evidences_on_evidence_id"
    t.index ["organization_id"], name: "index_clarification_evidences_on_organization_id"
  end

  create_table "clarification_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "engineering_review_id", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.text "question", null: false
    t.bigint "recipient_membership_id", null: false
    t.datetime "requested_at", null: false
    t.bigint "requested_by_id", null: false
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "responded_at"
    t.bigint "responded_by_membership_id"
    t.text "response"
    t.string "state", default: "requested", null: false
    t.bigint "target_id", null: false
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.index ["engineering_review_id", "state"], name: "idx_on_engineering_review_id_state_7fb600b7d8"
    t.index ["engineering_review_id"], name: "index_clarification_requests_on_engineering_review_id"
    t.index ["execution_id"], name: "index_clarification_requests_on_execution_id"
    t.index ["id", "organization_id"], name: "index_clarification_requests_on_id_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_clarification_requests_on_organization_id"
    t.index ["recipient_membership_id", "state", "updated_at"], name: "index_clarifications_on_recipient_state"
    t.index ["recipient_membership_id"], name: "index_clarification_requests_on_recipient_membership_id"
    t.index ["requested_by_id"], name: "index_clarification_requests_on_requested_by_id"
    t.index ["resolved_by_id"], name: "index_clarification_requests_on_resolved_by_id"
    t.index ["responded_by_membership_id"], name: "index_clarification_requests_on_responded_by_membership_id"
    t.index ["target_type", "target_id"], name: "index_clarification_requests_on_target_type_and_target_id"
    t.check_constraint "btrim(question) <> ''::text", name: "clarification_requests_question_present"
    t.check_constraint "state::text = 'requested'::text AND response IS NULL AND responded_by_membership_id IS NULL AND responded_at IS NULL AND resolved_by_id IS NULL AND resolved_at IS NULL OR state::text = 'responded'::text AND btrim(response) <> ''::text AND responded_by_membership_id IS NOT NULL AND responded_at IS NOT NULL AND resolved_by_id IS NULL AND resolved_at IS NULL OR state::text = 'resolved'::text AND btrim(response) <> ''::text AND responded_by_membership_id IS NOT NULL AND responded_at IS NOT NULL AND resolved_by_id IS NOT NULL AND resolved_at IS NOT NULL", name: "clarification_requests_lifecycle_check"
    t.check_constraint "state::text = ANY (ARRAY['requested'::character varying, 'responded'::character varying, 'resolved'::character varying]::text[])", name: "clarification_requests_state_check"
    t.check_constraint "target_type::text = ANY (ARRAY['WorkOrder'::character varying, 'Execution'::character varying, 'Finding'::character varying, 'Measurement'::character varying, 'ActionPerformed'::character varying, 'MaterialUsed'::character varying, 'Recommendation'::character varying, 'Evidence'::character varying]::text[])", name: "clarification_requests_target_type_check"
  end

  create_table "customers", force: :cascade do |t|
    t.string "business_identifier"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "legal_name"
    t.string "name", null: false
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((name)::text)", name: "index_customers_on_organization_and_lower_name", unique: true
    t.index ["id", "organization_id"], name: "index_customers_on_id_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_customers_on_organization_id"
  end

  create_table "engineering_review_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "engineering_review_id", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["engineering_review_id", "execution_id"], name: "index_review_executions_on_review_and_execution", unique: true
    t.index ["engineering_review_id"], name: "index_engineering_review_executions_on_engineering_review_id"
    t.index ["execution_id"], name: "index_engineering_review_executions_on_execution_id"
    t.index ["organization_id"], name: "index_engineering_review_executions_on_organization_id"
  end

  create_table "engineering_reviews", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.bigint "reviewer_id"
    t.datetime "started_at"
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["approved_by_id"], name: "index_engineering_reviews_on_approved_by_id"
    t.index ["id", "organization_id"], name: "index_engineering_reviews_on_id_and_organization_id", unique: true
    t.index ["organization_id", "state", "updated_at"], name: "idx_on_organization_id_state_updated_at_3251521b2b"
    t.index ["organization_id"], name: "index_engineering_reviews_on_organization_id"
    t.index ["reviewer_id"], name: "index_engineering_reviews_on_reviewer_id"
    t.index ["work_order_id"], name: "index_engineering_reviews_on_work_order_id", unique: true
    t.check_constraint "state::text = 'approved'::text AND approved_by_id IS NOT NULL AND approved_at IS NOT NULL OR state::text <> 'approved'::text AND approved_by_id IS NULL AND approved_at IS NULL", name: "engineering_reviews_approval_state_check"
    t.check_constraint "state::text = 'pending'::text AND reviewer_id IS NULL AND started_at IS NULL OR state::text <> 'pending'::text AND reviewer_id IS NOT NULL AND started_at IS NOT NULL", name: "engineering_reviews_reviewer_state_check"
    t.check_constraint "state::text = ANY (ARRAY['pending'::character varying, 'in_review'::character varying, 'changes_requested'::character varying, 'approved'::character varying]::text[])", name: "engineering_reviews_state_check"
  end

  create_table "evidence_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "evidence_id", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "supporting", null: false
    t.bigint "technical_record_id", null: false
    t.string "technical_record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["evidence_id", "execution_id", "organization_id"], name: "index_evidence_references_on_evidence_execution_org"
    t.index ["evidence_id"], name: "index_evidence_references_on_evidence_id"
    t.index ["execution_id", "organization_id"], name: "index_evidence_references_on_execution_id_and_organization_id"
    t.index ["execution_id"], name: "index_evidence_references_on_execution_id"
    t.index ["organization_id"], name: "index_evidence_references_on_organization_id"
    t.index ["technical_record_type", "technical_record_id", "evidence_id", "role"], name: "index_evidence_references_on_record_evidence_and_role", unique: true
    t.check_constraint "role::text = ANY (ARRAY['supporting'::character varying, 'before'::character varying, 'after'::character varying]::text[])", name: "evidence_references_role_check"
    t.check_constraint "technical_record_type::text = ANY (ARRAY['Finding'::character varying, 'Measurement'::character varying, 'ActionPerformed'::character varying, 'MaterialUsed'::character varying, 'Recommendation'::character varying]::text[])", name: "evidence_references_record_type_check"
  end

  create_table "evidences", force: :cascade do |t|
    t.datetime "accepted_at", null: false
    t.bigint "byte_size", null: false
    t.datetime "captured_at"
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "evidence_type", null: false
    t.bigint "execution_id", null: false
    t.string "integrity_algorithm", default: "SHA-256", null: false
    t.string "integrity_digest", null: false
    t.bigint "organization_id", null: false
    t.string "original_filename", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_membership_id", null: false
    t.index ["execution_id", "organization_id"], name: "index_evidences_on_execution_id_and_organization_id"
    t.index ["execution_id"], name: "index_evidences_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_evidences_on_id_execution_and_organization", unique: true
    t.index ["id", "organization_id"], name: "index_evidences_on_id_and_organization_id", unique: true
    t.index ["integrity_digest"], name: "index_evidences_on_integrity_digest"
    t.index ["organization_id"], name: "index_evidences_on_organization_id"
    t.index ["uploaded_by_membership_id", "organization_id"], name: "idx_on_uploaded_by_membership_id_organization_id_16187e70a2"
    t.index ["uploaded_by_membership_id"], name: "index_evidences_on_uploaded_by_membership_id"
    t.check_constraint "byte_size > 0", name: "evidences_positive_byte_size"
    t.check_constraint "integrity_algorithm::text = 'SHA-256'::text", name: "evidences_sha256_algorithm"
    t.check_constraint "length(integrity_digest::text) = 64", name: "evidences_sha256_digest_length"
  end

  create_table "execution_events", force: :cascade do |t|
    t.bigint "actor_membership_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.bigint "execution_id", null: false
    t.datetime "occurred_at", null: false
    t.bigint "organization_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["actor_membership_id", "organization_id"], name: "idx_on_actor_membership_id_organization_id_a846e26131"
    t.index ["actor_membership_id"], name: "index_execution_events_on_actor_membership_id"
    t.index ["execution_id", "occurred_at", "id"], name: "index_execution_events_on_chronology"
    t.index ["execution_id", "organization_id"], name: "index_execution_events_on_execution_id_and_organization_id"
    t.index ["execution_id"], name: "index_execution_events_on_execution_id"
    t.index ["organization_id"], name: "index_execution_events_on_organization_id"
    t.check_constraint "event_type::text = 'paused_asset_work'::text OR reason IS NULL", name: "execution_events_pause_reason_check"
    t.check_constraint "event_type::text = ANY (ARRAY['arrived_at_site'::character varying, 'started_asset_work'::character varying, 'paused_asset_work'::character varying, 'resumed_asset_work'::character varying, 'finished_asset_work'::character varying, 'left_site'::character varying, 'submitted'::character varying]::text[])", name: "execution_events_event_type_check"
    t.check_constraint "reason IS NULL OR (reason::text = ANY (ARRAY['customer_request'::character varying, 'access_wait'::character varying, 'production'::character varying, 'safety'::character varying, 'material'::character varying, 'break'::character varying, 'other'::character varying]::text[]))", name: "execution_events_reason_check"
  end

  create_table "execution_participants", force: :cascade do |t|
    t.bigint "added_by_id", null: false
    t.datetime "created_at", null: false
    t.bigint "execution_id", null: false
    t.bigint "membership_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_execution_participants_on_added_by_id"
    t.index ["execution_id", "membership_id"], name: "index_execution_participants_on_execution_id_and_membership_id", unique: true
    t.index ["execution_id", "organization_id"], name: "idx_on_execution_id_organization_id_c629b406d9"
    t.index ["execution_id"], name: "index_execution_participants_on_execution_id"
    t.index ["membership_id", "organization_id"], name: "idx_on_membership_id_organization_id_d0f772174f"
    t.index ["membership_id"], name: "index_execution_participants_on_membership_id"
    t.index ["organization_id"], name: "index_execution_participants_on_organization_id"
  end

  create_table "executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "organization_id", null: false
    t.string "outcome"
    t.text "outcome_note"
    t.string "outcome_reason"
    t.datetime "outcome_recorded_at"
    t.bigint "outcome_recorded_by_membership_id"
    t.datetime "scheduled_start"
    t.datetime "updated_at", null: false
    t.bigint "visit_number", null: false
    t.bigint "work_order_id", null: false
    t.index ["created_by_id"], name: "index_executions_on_created_by_id"
    t.index ["id", "organization_id"], name: "index_executions_on_id_and_organization_id", unique: true
    t.index ["id", "work_order_id", "organization_id"], name: "index_executions_on_id_work_order_and_organization", unique: true
    t.index ["organization_id", "scheduled_start"], name: "index_executions_on_organization_id_and_scheduled_start"
    t.index ["organization_id"], name: "index_executions_on_organization_id"
    t.index ["outcome_recorded_by_membership_id"], name: "index_executions_on_outcome_recorded_by_membership_id"
    t.index ["work_order_id", "visit_number"], name: "index_executions_on_work_order_id_and_visit_number", unique: true
    t.index ["work_order_id"], name: "index_executions_on_work_order_id"
    t.check_constraint "outcome IS NULL AND outcome_reason IS NULL AND outcome_recorded_at IS NULL AND outcome_recorded_by_membership_id IS NULL OR outcome::text = 'completed'::text AND outcome_reason IS NULL AND outcome_recorded_at IS NOT NULL AND outcome_recorded_by_membership_id IS NOT NULL OR (outcome::text = ANY (ARRAY['return_required'::character varying, 'unable_to_execute'::character varying]::text[])) AND outcome_reason IS NOT NULL AND outcome_recorded_at IS NOT NULL AND outcome_recorded_by_membership_id IS NOT NULL", name: "executions_outcome_metadata_check"
    t.check_constraint "outcome IS NULL OR (outcome::text = ANY (ARRAY['completed'::character varying, 'return_required'::character varying, 'unable_to_execute'::character varying]::text[]))", name: "executions_outcome_check"
    t.check_constraint "outcome_reason IS NULL OR (outcome_reason::text = ANY (ARRAY['material_required'::character varying, 'customer_unavailable'::character varying, 'equipment_unavailable'::character varying, 'additional_personnel_required'::character varying, 'additional_diagnosis_required'::character varying, 'access_denied'::character varying, 'unsafe_condition'::character varying, 'wrong_equipment'::character varying, 'production_unavailable'::character varying, 'other'::character varying]::text[]))", name: "executions_outcome_reason_check"
    t.check_constraint "visit_number > 0", name: "executions_visit_number_check"
  end

  create_table "findings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_membership_id", null: false
    t.string "severity", default: "significant", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "recorded_at", "id"], name: "index_findings_on_chronology"
    t.index ["execution_id"], name: "index_findings_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_findings_on_id_execution_and_org", unique: true
    t.index ["organization_id"], name: "index_findings_on_organization_id"
    t.index ["recorded_by_membership_id", "organization_id"], name: "index_findings_on_recorder_and_org"
    t.index ["recorded_by_membership_id"], name: "index_findings_on_recorded_by_membership_id"
    t.check_constraint "btrim(description) <> ''::text", name: "findings_description_present"
    t.check_constraint "severity::text = ANY (ARRAY['minor'::character varying, 'significant'::character varying, 'critical'::character varying]::text[])", name: "findings_severity_check"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "revoked_at"
    t.string "roles", default: [], null: false, array: true
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id", "email"], name: "index_invitations_on_organization_id_and_email"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
    t.check_constraint "cardinality(roles) > 0 AND roles <@ ARRAY['administrator'::character varying, 'supervisor'::character varying, 'technician'::character varying, 'engineer'::character varying]", name: "invitations_roles_check"
  end

  create_table "login_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_login_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_login_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_login_tokens_on_user_id"
  end

  create_table "materials_used", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.decimal "quantity", precision: 14, scale: 3, null: false
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_membership_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "recorded_at", "id"], name: "index_materials_used_on_chronology"
    t.index ["execution_id"], name: "index_materials_used_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_materials_used_on_id_execution_and_org", unique: true
    t.index ["organization_id"], name: "index_materials_used_on_organization_id"
    t.index ["recorded_by_membership_id", "organization_id"], name: "index_materials_used_on_recorder_and_org"
    t.index ["recorded_by_membership_id"], name: "index_materials_used_on_recorded_by_membership_id"
    t.check_constraint "btrim(description) <> ''::text", name: "materials_used_description_present"
    t.check_constraint "quantity > 0::numeric", name: "materials_used_positive_quantity"
    t.check_constraint "unit::text = ANY (ARRAY['piece'::character varying, 'm'::character varying, 'cm'::character varying, 'mm'::character varying, 'kg'::character varying, 'g'::character varying, 'L'::character varying, 'mL'::character varying]::text[])", name: "materials_used_unit_check"
  end

  create_table "measurements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "execution_id", null: false
    t.string "measurement_point", null: false
    t.bigint "organization_id", null: false
    t.string "quantity", null: false
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_membership_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 18, scale: 6, null: false
    t.index ["execution_id", "recorded_at", "id"], name: "index_measurements_on_chronology"
    t.index ["execution_id"], name: "index_measurements_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_measurements_on_id_execution_and_org", unique: true
    t.index ["organization_id"], name: "index_measurements_on_organization_id"
    t.index ["recorded_by_membership_id", "organization_id"], name: "index_measurements_on_recorder_and_org"
    t.index ["recorded_by_membership_id"], name: "index_measurements_on_recorded_by_membership_id"
    t.check_constraint "btrim(measurement_point::text) <> ''::text", name: "measurements_point_present"
    t.check_constraint "quantity::text = 'voltage'::text AND unit::text = 'mV'::text OR quantity::text = 'voltage'::text AND unit::text = 'V'::text OR quantity::text = 'voltage'::text AND unit::text = 'kV'::text OR quantity::text = 'current'::text AND unit::text = 'mA'::text OR quantity::text = 'current'::text AND unit::text = 'A'::text OR quantity::text = 'frequency'::text AND unit::text = 'Hz'::text OR quantity::text = 'resistance'::text AND unit::text = 'ohm'::text OR quantity::text = 'resistance'::text AND unit::text = 'kohm'::text OR quantity::text = 'resistance'::text AND unit::text = 'Mohm'::text OR quantity::text = 'insulation_resistance'::text AND unit::text = 'kohm'::text OR quantity::text = 'insulation_resistance'::text AND unit::text = 'Mohm'::text OR quantity::text = 'insulation_resistance'::text AND unit::text = 'Gohm'::text OR quantity::text = 'continuity'::text AND unit::text = 'ohm'::text OR quantity::text = 'temperature'::text AND unit::text = 'degC'::text", name: "measurements_quantity_unit_check"
  end

  create_table "membership_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "membership_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["membership_id", "role"], name: "index_membership_roles_on_membership_id_and_role", unique: true
    t.index ["membership_id"], name: "index_membership_roles_on_membership_id"
    t.check_constraint "role::text = ANY (ARRAY['administrator'::character varying, 'supervisor'::character varying, 'technician'::character varying, 'engineer'::character varying]::text[])", name: "membership_roles_role_check"
  end

  create_table "memberships", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["id", "organization_id"], name: "index_memberships_on_id_and_organization_id", unique: true
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_sequence", default: 0, null: false
    t.check_constraint "work_order_sequence >= 0", name: "organizations_work_order_sequence_check"
  end

  create_table "recommendations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "execution_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_id", "recorded_at", "id"], name: "index_recommendations_on_chronology"
    t.index ["execution_id"], name: "index_recommendations_on_execution_id"
    t.index ["id", "execution_id", "organization_id"], name: "index_recommendations_on_id_execution_and_org", unique: true
    t.index ["organization_id"], name: "index_recommendations_on_organization_id"
    t.index ["recorded_by_membership_id", "organization_id"], name: "index_recommendations_on_recorder_and_org"
    t.index ["recorded_by_membership_id"], name: "index_recommendations_on_recorded_by_membership_id"
    t.check_constraint "btrim(description) <> ''::text", name: "recommendations_description_present"
  end

  create_table "service_types", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((name)::text)", name: "index_service_types_on_organization_and_lower_name", unique: true
    t.index ["id", "organization_id"], name: "index_service_types_on_id_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_service_types_on_organization_id"
  end

  create_table "sites", force: :cascade do |t|
    t.text "address"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index "customer_id, lower((name)::text)", name: "index_sites_on_customer_and_lower_name", unique: true
    t.index ["customer_id", "organization_id"], name: "index_sites_on_customer_id_and_organization_id"
    t.index ["customer_id"], name: "index_sites_on_customer_id"
    t.index ["id", "customer_id", "organization_id"], name: "index_sites_on_id_and_customer_id_and_organization_id", unique: true
    t.index ["id", "organization_id"], name: "index_sites_on_id_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_sites_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "founder", default: false, null: false
    t.datetime "last_seen_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "work_orders", force: :cascade do |t|
    t.bigint "asset_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "organization_id", null: false
    t.string "priority", default: "normal", null: false
    t.string "public_identifier", null: false
    t.text "requested_work", null: false
    t.datetime "scheduled_start"
    t.bigint "sequence_number", null: false
    t.bigint "service_type_id", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_work_orders_on_asset_id"
    t.index ["created_by_id"], name: "index_work_orders_on_created_by_id"
    t.index ["customer_id"], name: "index_work_orders_on_customer_id"
    t.index ["id", "organization_id"], name: "index_work_orders_on_id_and_organization_id", unique: true
    t.index ["organization_id", "public_identifier"], name: "index_work_orders_on_organization_id_and_public_identifier", unique: true
    t.index ["organization_id", "scheduled_start"], name: "index_work_orders_on_organization_id_and_scheduled_start"
    t.index ["organization_id", "sequence_number"], name: "index_work_orders_on_organization_id_and_sequence_number", unique: true
    t.index ["organization_id"], name: "index_work_orders_on_organization_id"
    t.index ["service_type_id"], name: "index_work_orders_on_service_type_id"
    t.index ["site_id"], name: "index_work_orders_on_site_id"
    t.check_constraint "priority::text = ANY (ARRAY['normal'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])", name: "work_orders_priority_check"
    t.check_constraint "sequence_number > 0", name: "work_orders_sequence_number_check"
  end

  add_foreign_key "action_performeds", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "action_performeds", "memberships", column: ["recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "action_performeds", "organizations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assets", "organizations"
  add_foreign_key "assets", "sites", column: ["site_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "assignments", "memberships", column: ["membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "assignments", "organizations"
  add_foreign_key "assignments", "users", column: "assigned_by_id"
  add_foreign_key "assignments", "work_orders", column: ["work_order_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_evidences", "clarification_requests", column: ["clarification_request_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_evidences", "evidences", column: ["evidence_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_evidences", "organizations"
  add_foreign_key "clarification_requests", "engineering_reviews", column: ["engineering_review_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_requests", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_requests", "memberships", column: ["recipient_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_requests", "memberships", column: ["responded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "clarification_requests", "organizations"
  add_foreign_key "clarification_requests", "users", column: "requested_by_id"
  add_foreign_key "clarification_requests", "users", column: "resolved_by_id"
  add_foreign_key "customers", "organizations"
  add_foreign_key "engineering_review_executions", "engineering_reviews", column: ["engineering_review_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "engineering_review_executions", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "engineering_review_executions", "organizations"
  add_foreign_key "engineering_reviews", "organizations"
  add_foreign_key "engineering_reviews", "users", column: "approved_by_id"
  add_foreign_key "engineering_reviews", "users", column: "reviewer_id"
  add_foreign_key "engineering_reviews", "work_orders", column: ["work_order_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "evidence_references", "evidences", column: ["evidence_id", "execution_id", "organization_id"], primary_key: ["id", "execution_id", "organization_id"]
  add_foreign_key "evidence_references", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "evidence_references", "organizations"
  add_foreign_key "evidences", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "evidences", "memberships", column: ["uploaded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "evidences", "organizations"
  add_foreign_key "execution_events", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "execution_events", "memberships", column: ["actor_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "execution_events", "organizations"
  add_foreign_key "execution_participants", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "execution_participants", "memberships", column: ["membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "execution_participants", "organizations"
  add_foreign_key "execution_participants", "users", column: "added_by_id"
  add_foreign_key "executions", "memberships", column: ["outcome_recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "executions", "organizations"
  add_foreign_key "executions", "users", column: "created_by_id"
  add_foreign_key "executions", "work_orders", column: ["work_order_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "findings", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "findings", "memberships", column: ["recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "findings", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "materials_used", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "materials_used", "memberships", column: ["recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "materials_used", "organizations"
  add_foreign_key "measurements", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "measurements", "memberships", column: ["recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "measurements", "organizations"
  add_foreign_key "membership_roles", "memberships"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "recommendations", "executions", column: ["execution_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "recommendations", "memberships", column: ["recorded_by_membership_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "recommendations", "organizations"
  add_foreign_key "service_types", "organizations"
  add_foreign_key "sites", "customers", column: ["customer_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "sites", "organizations"
  add_foreign_key "work_orders", "assets", column: ["asset_id", "site_id", "organization_id"], primary_key: ["id", "site_id", "organization_id"]
  add_foreign_key "work_orders", "customers", column: ["customer_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "work_orders", "organizations"
  add_foreign_key "work_orders", "service_types", column: ["service_type_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "work_orders", "sites", column: ["site_id", "customer_id", "organization_id"], primary_key: ["id", "customer_id", "organization_id"]
  add_foreign_key "work_orders", "users", column: "created_by_id"
end
