class CreateServiceTypesWorkOrdersAndAssignments < ActiveRecord::Migration[8.1]
  PRIORITIES = %w[normal high urgent].freeze

  def change
    add_column :organizations, :work_order_sequence, :bigint, null: false, default: 0
    add_check_constraint :organizations, "work_order_sequence >= 0",
                         name: "organizations_work_order_sequence_check"

    add_index :memberships, %i[id organization_id], unique: true
    add_index :assets, %i[id site_id organization_id], unique: true
    add_index :sites, %i[id customer_id organization_id], unique: true

    create_table :service_types do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :service_types, %i[id organization_id], unique: true
    add_index :service_types, "organization_id, lower(name)", unique: true,
                                                              name: "index_service_types_on_organization_and_lower_name"

    create_table :work_orders do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :customer, null: false
      t.references :site, null: false
      t.references :asset
      t.references :service_type, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.bigint :sequence_number, null: false
      t.string :public_identifier, null: false
      t.text :requested_work, null: false
      t.string :priority, null: false, default: "normal"
      t.datetime :scheduled_start

      t.timestamps
    end
    add_index :work_orders, %i[id organization_id], unique: true
    add_index :work_orders, %i[organization_id sequence_number], unique: true
    add_index :work_orders, %i[organization_id public_identifier], unique: true
    add_index :work_orders, %i[organization_id scheduled_start]
    add_foreign_key :work_orders, :customers,
                    column: %i[customer_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :work_orders, :sites,
                    column: %i[site_id customer_id organization_id],
                    primary_key: %i[id customer_id organization_id]
    add_foreign_key :work_orders, :assets,
                    column: %i[asset_id site_id organization_id],
                    primary_key: %i[id site_id organization_id]
    add_foreign_key :work_orders, :service_types,
                    column: %i[service_type_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :work_orders,
                         "priority IN (#{PRIORITIES.map { |priority| quote(priority) }.join(', ')})",
                         name: "work_orders_priority_check"
    add_check_constraint :work_orders, "sequence_number > 0",
                         name: "work_orders_sequence_number_check"

    create_table :assignments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :work_order, null: false
      t.references :membership, null: false
      t.references :assigned_by, null: false, foreign_key: { to_table: :users }
      t.datetime :assigned_at, null: false
      t.datetime :ended_at

      t.timestamps
    end
    add_index :assignments, %i[work_order_id organization_id]
    add_index :assignments, %i[membership_id organization_id]
    add_index :assignments, :work_order_id, unique: true, where: "ended_at IS NULL",
                                                   name: "index_assignments_on_current_work_order"
    add_foreign_key :assignments, :work_orders,
                    column: %i[work_order_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :assignments, :memberships,
                    column: %i[membership_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :assignments, "ended_at IS NULL OR ended_at >= assigned_at",
                         name: "assignments_timeline_check"
  end
end
