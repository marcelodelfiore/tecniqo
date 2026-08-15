class CreateExecutionsParticipantsAndEvents < ActiveRecord::Migration[8.1]
  EVENT_TYPES = %w[
    arrived_at_site started_asset_work paused_asset_work resumed_asset_work
    finished_asset_work left_site submitted
  ].freeze
  PAUSE_REASONS = %w[customer_request access_wait production safety material break other].freeze
  OUTCOMES = %w[completed return_required unable_to_execute].freeze
  OUTCOME_REASONS = %w[
    material_required customer_unavailable equipment_unavailable
    additional_personnel_required additional_diagnosis_required access_denied
    unsafe_condition wrong_equipment production_unavailable other
  ].freeze

  def change
    create_table :executions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :work_order, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.bigint :visit_number, null: false
      t.datetime :scheduled_start
      t.string :outcome
      t.string :outcome_reason
      t.text :outcome_note
      t.datetime :outcome_recorded_at
      t.references :outcome_recorded_by_membership

      t.timestamps
    end
    add_index :executions, %i[id organization_id], unique: true
    add_index :executions, %i[id work_order_id organization_id], unique: true,
                                                                name: "index_executions_on_id_work_order_and_organization"
    add_index :executions, %i[work_order_id visit_number], unique: true
    add_index :executions, %i[organization_id scheduled_start]
    add_foreign_key :executions, :work_orders,
                    column: %i[work_order_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :executions, :memberships,
                    column: %i[outcome_recorded_by_membership_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :executions, "visit_number > 0", name: "executions_visit_number_check"
    add_check_constraint :executions,
                         "outcome IS NULL OR outcome IN (#{quoted(OUTCOMES)})",
                         name: "executions_outcome_check"
    add_check_constraint :executions,
                         "outcome_reason IS NULL OR outcome_reason IN (#{quoted(OUTCOME_REASONS)})",
                         name: "executions_outcome_reason_check"
    add_check_constraint :executions,
                         <<~SQL.squish,
                           (outcome IS NULL AND outcome_reason IS NULL AND outcome_recorded_at IS NULL AND outcome_recorded_by_membership_id IS NULL)
                           OR
                           (outcome = 'completed' AND outcome_reason IS NULL AND outcome_recorded_at IS NOT NULL AND outcome_recorded_by_membership_id IS NOT NULL)
                           OR
                           (outcome IN ('return_required', 'unable_to_execute') AND outcome_reason IS NOT NULL AND outcome_recorded_at IS NOT NULL AND outcome_recorded_by_membership_id IS NOT NULL)
                         SQL
                         name: "executions_outcome_metadata_check"

    create_table :execution_participants do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :execution, null: false
      t.references :membership, null: false
      t.references :added_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :execution_participants, %i[execution_id membership_id], unique: true
    add_index :execution_participants, %i[execution_id organization_id]
    add_index :execution_participants, %i[membership_id organization_id]
    add_foreign_key :execution_participants, :executions,
                    column: %i[execution_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :execution_participants, :memberships,
                    column: %i[membership_id organization_id],
                    primary_key: %i[id organization_id]

    create_table :execution_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :execution, null: false
      t.references :actor_membership, null: false
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.string :reason

      t.timestamps
    end
    add_index :execution_events, %i[execution_id occurred_at id],
                                 name: "index_execution_events_on_chronology"
    add_index :execution_events, %i[execution_id organization_id]
    add_index :execution_events, %i[actor_membership_id organization_id]
    add_foreign_key :execution_events, :executions,
                    column: %i[execution_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :execution_events, :memberships,
                    column: %i[actor_membership_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :execution_events,
                         "event_type IN (#{quoted(EVENT_TYPES)})",
                         name: "execution_events_event_type_check"
    add_check_constraint :execution_events,
                         "reason IS NULL OR reason IN (#{quoted(PAUSE_REASONS)})",
                         name: "execution_events_reason_check"
    add_check_constraint :execution_events,
                         "event_type = 'paused_asset_work' OR reason IS NULL",
                         name: "execution_events_pause_reason_check"
  end

  private

  def quoted(values)
    values.map { |value| quote(value) }.join(", ")
  end
end
