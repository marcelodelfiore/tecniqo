class CreateOrganizationMembershipsAndRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :founder, :boolean, null: false, default: false

    create_table :organizations do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :memberships, %i[organization_id user_id], unique: true

    create_table :membership_roles do |t|
      t.references :membership, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end
    add_index :membership_roles, %i[membership_id role], unique: true
    add_check_constraint :membership_roles,
                         "role IN ('administrator', 'supervisor', 'technician', 'engineer')",
                         name: "membership_roles_role_check"
  end
end
