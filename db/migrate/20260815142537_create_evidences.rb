class CreateEvidences < ActiveRecord::Migration[8.1]
  def change
    create_table :evidences do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :execution, null: false
      t.references :uploaded_by_membership, null: false
      t.string :evidence_type, null: false
      t.text :description
      t.datetime :captured_at
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.string :integrity_algorithm, null: false, default: "SHA-256"
      t.string :integrity_digest, null: false
      t.datetime :accepted_at, null: false

      t.timestamps
    end

    add_index :evidences, %i[id organization_id], unique: true
    add_index :evidences, %i[execution_id organization_id]
    add_index :evidences, %i[uploaded_by_membership_id organization_id]
    add_index :evidences, :integrity_digest
    add_check_constraint :evidences, "byte_size > 0", name: "evidences_positive_byte_size"
    add_check_constraint :evidences, "integrity_algorithm = 'SHA-256'", name: "evidences_sha256_algorithm"
    add_check_constraint :evidences, "length(integrity_digest) = 64", name: "evidences_sha256_digest_length"
    add_foreign_key :evidences, :executions, column: %i[execution_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :evidences, :memberships,
                    column: %i[uploaded_by_membership_id organization_id],
                    primary_key: %i[id organization_id]
  end
end
