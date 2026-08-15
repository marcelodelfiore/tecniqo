class CreateCustomersSitesAndAssets < ActiveRecord::Migration[8.1]
  ASSET_TYPES = %w[motor electrical_panel transformer generator vfd ups spda capacitor_bank other].freeze

  def change
    create_table :customers do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :legal_name
      t.string :business_identifier
      t.string :email
      t.string :phone
      t.text :notes

      t.timestamps
    end
    add_index :customers, %i[id organization_id], unique: true
    add_index :customers, "organization_id, lower(name)", unique: true,
                                                           name: "index_customers_on_organization_and_lower_name"

    create_table :sites do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :customer, null: false
      t.string :name, null: false
      t.text :address
      t.string :contact_name
      t.string :phone
      t.text :notes

      t.timestamps
    end
    add_index :sites, %i[id organization_id], unique: true
    add_index :sites, %i[customer_id organization_id]
    add_index :sites, "customer_id, lower(name)", unique: true,
                                                   name: "index_sites_on_customer_and_lower_name"
    add_foreign_key :sites, :customers,
                    column: %i[customer_id organization_id],
                    primary_key: %i[id organization_id]

    create_table :assets do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :site, null: false
      t.string :name, null: false
      t.string :asset_type, null: false, default: "other"
      t.string :tag
      t.string :manufacturer
      t.string :model
      t.string :serial_number

      t.timestamps
    end
    add_index :assets, %i[site_id organization_id]
    add_foreign_key :assets, :sites,
                    column: %i[site_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :assets,
                         "asset_type IN (#{ASSET_TYPES.map { |type| quote(type) }.join(', ')})",
                         name: "assets_asset_type_check"
  end
end
