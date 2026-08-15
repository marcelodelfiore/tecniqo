class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :roles, array: true, null: false, default: []
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :invitations, :token_digest, unique: true
    add_index :invitations, %i[organization_id email]
    add_check_constraint :invitations,
                         "cardinality(roles) > 0 AND roles <@ ARRAY['administrator', 'supervisor', 'technician', 'engineer']::varchar[]",
                         name: "invitations_roles_check"
  end
end
