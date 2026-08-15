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

ActiveRecord::Schema[8.1].define(version: 2026_08_15_020000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["organization_id"], name: "index_assets_on_organization_id"
    t.index ["site_id", "organization_id"], name: "index_assets_on_site_id_and_organization_id"
    t.index ["site_id"], name: "index_assets_on_site_id"
    t.check_constraint "asset_type::text = ANY (ARRAY['motor'::character varying, 'electrical_panel'::character varying, 'transformer'::character varying, 'generator'::character varying, 'vfd'::character varying, 'ups'::character varying, 'spda'::character varying, 'capacitor_bank'::character varying, 'other'::character varying]::text[])", name: "assets_asset_type_check"
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
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
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

  add_foreign_key "assets", "organizations"
  add_foreign_key "assets", "sites", column: ["site_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "customers", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "membership_roles", "memberships"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "sites", "customers", column: ["customer_id", "organization_id"], primary_key: ["id", "organization_id"]
  add_foreign_key "sites", "organizations"
end
