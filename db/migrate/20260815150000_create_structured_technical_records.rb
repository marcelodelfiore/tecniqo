class CreateStructuredTechnicalRecords < ActiveRecord::Migration[8.1]
  FINDING_SEVERITIES = %w[minor significant critical].freeze
  MEASUREMENT_PAIRS = {
    "voltage" => %w[mV V kV],
    "current" => %w[mA A],
    "frequency" => %w[Hz],
    "resistance" => %w[ohm kohm Mohm],
    "insulation_resistance" => %w[kohm Mohm Gohm],
    "continuity" => %w[ohm],
    "temperature" => %w[degC]
  }.freeze
  MATERIAL_UNITS = %w[piece m cm mm kg g L mL].freeze
  EVIDENCE_ROLES = %w[supporting before after].freeze
  REFERENCE_TYPES = %w[Finding Measurement ActionPerformed MaterialUsed Recommendation].freeze

  def change
    create_technical_record_table(:findings) do |t|
      t.text :description, null: false
      t.string :severity, null: false, default: "significant"
    end
    add_check_constraint :findings, "btrim(description) <> ''", name: "findings_description_present"
    add_check_constraint :findings, "severity IN (#{quoted(FINDING_SEVERITIES)})",
                         name: "findings_severity_check"

    create_technical_record_table(:measurements) do |t|
      t.string :quantity, null: false
      t.decimal :value, precision: 18, scale: 6, null: false
      t.string :unit, null: false
      t.string :measurement_point, null: false
    end
    measurement_pair_sql = MEASUREMENT_PAIRS.flat_map do |quantity, units|
      units.map { |unit| "(quantity = #{quote(quantity)} AND unit = #{quote(unit)})" }
    end.join(" OR ")
    add_check_constraint :measurements, measurement_pair_sql, name: "measurements_quantity_unit_check"
    add_check_constraint :measurements, "btrim(measurement_point) <> ''",
                         name: "measurements_point_present"

    create_technical_record_table(:action_performeds) do |t|
      t.text :description, null: false
    end
    add_check_constraint :action_performeds, "btrim(description) <> ''",
                         name: "action_performeds_description_present"

    create_technical_record_table(:materials_used) do |t|
      t.text :description, null: false
      t.decimal :quantity, precision: 14, scale: 3, null: false
      t.string :unit, null: false
    end
    add_check_constraint :materials_used, "btrim(description) <> ''",
                         name: "materials_used_description_present"
    add_check_constraint :materials_used, "quantity > 0", name: "materials_used_positive_quantity"
    add_check_constraint :materials_used, "unit IN (#{quoted(MATERIAL_UNITS)})",
                         name: "materials_used_unit_check"

    create_technical_record_table(:recommendations) do |t|
      t.text :description, null: false
    end
    add_check_constraint :recommendations, "btrim(description) <> ''",
                         name: "recommendations_description_present"

    add_index :evidences, %i[id execution_id organization_id], unique: true,
                                                                name: "index_evidences_on_id_execution_and_organization"
    create_table :evidence_references do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :execution, null: false
      t.references :evidence, null: false
      t.string :technical_record_type, null: false
      t.bigint :technical_record_id, null: false
      t.string :role, null: false, default: "supporting"

      t.timestamps
    end
    add_index :evidence_references,
              %i[technical_record_type technical_record_id evidence_id role], unique: true,
              name: "index_evidence_references_on_record_evidence_and_role"
    add_index :evidence_references, %i[execution_id organization_id]
    add_index :evidence_references, %i[evidence_id execution_id organization_id],
              name: "index_evidence_references_on_evidence_execution_org"
    add_foreign_key :evidence_references, :executions,
                    column: %i[execution_id organization_id], primary_key: %i[id organization_id]
    add_foreign_key :evidence_references, :evidences,
                    column: %i[evidence_id execution_id organization_id],
                    primary_key: %i[id execution_id organization_id]
    add_check_constraint :evidence_references,
                         "technical_record_type IN (#{quoted(REFERENCE_TYPES)})",
                         name: "evidence_references_record_type_check"
    add_check_constraint :evidence_references, "role IN (#{quoted(EVIDENCE_ROLES)})",
                         name: "evidence_references_role_check"
  end

  private

  def create_technical_record_table(name)
    create_table name do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :execution, null: false
      t.references :recorded_by_membership, null: false
      t.datetime :recorded_at, null: false
      yield t
      t.timestamps
    end
    add_index name, %i[id execution_id organization_id], unique: true,
                                                        name: "index_#{name}_on_id_execution_and_org"
    add_index name, %i[recorded_by_membership_id organization_id],
                    name: "index_#{name}_on_recorder_and_org"
    add_index name, %i[execution_id recorded_at id], name: "index_#{name}_on_chronology"
    add_foreign_key name, :executions, column: %i[execution_id organization_id],
                                        primary_key: %i[id organization_id]
    add_foreign_key name, :memberships,
                    column: %i[recorded_by_membership_id organization_id],
                    primary_key: %i[id organization_id]
  end

  def quoted(values)
    values.map { |value| quote(value) }.join(", ")
  end
end
