class CreateEngineeringReviewsAndClarifications < ActiveRecord::Migration[8.1]
  REVIEW_STATES = %w[pending in_review changes_requested approved].freeze
  CLARIFICATION_STATES = %w[requested responded resolved].freeze
  TARGET_TYPES = %w[
    WorkOrder Execution Finding Measurement ActionPerformed MaterialUsed Recommendation Evidence
  ].freeze

  def change
    create_table :engineering_reviews do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :work_order, null: false, index: { unique: true }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.string :state, null: false, default: "pending"
      t.datetime :started_at
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at

      t.timestamps
    end
    add_index :engineering_reviews, %i[id organization_id], unique: true
    add_index :engineering_reviews, %i[organization_id state updated_at]
    add_foreign_key :engineering_reviews, :work_orders,
                    column: %i[work_order_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :engineering_reviews, "state IN (#{quoted(REVIEW_STATES)})",
                         name: "engineering_reviews_state_check"
    add_check_constraint :engineering_reviews,
                         "(state = 'pending' AND reviewer_id IS NULL AND started_at IS NULL) OR " \
                         "(state <> 'pending' AND reviewer_id IS NOT NULL AND started_at IS NOT NULL)",
                         name: "engineering_reviews_reviewer_state_check"
    add_check_constraint :engineering_reviews,
                         "(state = 'approved' AND approved_by_id IS NOT NULL AND approved_at IS NOT NULL) OR " \
                         "(state <> 'approved' AND approved_by_id IS NULL AND approved_at IS NULL)",
                         name: "engineering_reviews_approval_state_check"

    create_table :engineering_review_executions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :engineering_review, null: false
      t.references :execution, null: false

      t.timestamps
    end
    add_index :engineering_review_executions, %i[engineering_review_id execution_id],
              unique: true, name: "index_review_executions_on_review_and_execution"
    add_foreign_key :engineering_review_executions, :engineering_reviews,
                    column: %i[engineering_review_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :engineering_review_executions, :executions,
                    column: %i[execution_id organization_id],
                    primary_key: %i[id organization_id]

    create_table :clarification_requests do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :engineering_review, null: false
      t.references :execution, null: false
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.references :recipient_membership, null: false
      t.text :question, null: false
      t.string :state, null: false, default: "requested"
      t.datetime :requested_at, null: false
      t.text :response
      t.references :responded_by_membership
      t.datetime :responded_at
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :clarification_requests, %i[target_type target_id]
    add_index :clarification_requests, %i[id organization_id], unique: true
    add_index :clarification_requests, %i[recipient_membership_id state updated_at],
              name: "index_clarifications_on_recipient_state"
    add_index :clarification_requests, %i[engineering_review_id state]
    add_foreign_key :clarification_requests, :engineering_reviews,
                    column: %i[engineering_review_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :clarification_requests, :executions,
                    column: %i[execution_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :clarification_requests, :memberships,
                    column: %i[recipient_membership_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :clarification_requests, :memberships,
                    column: %i[responded_by_membership_id organization_id],
                    primary_key: %i[id organization_id]
    add_check_constraint :clarification_requests, "target_type IN (#{quoted(TARGET_TYPES)})",
                         name: "clarification_requests_target_type_check"
    add_check_constraint :clarification_requests, "state IN (#{quoted(CLARIFICATION_STATES)})",
                         name: "clarification_requests_state_check"
    add_check_constraint :clarification_requests, "btrim(question) <> ''",
                         name: "clarification_requests_question_present"
    add_check_constraint :clarification_requests,
                         "(state = 'requested' AND response IS NULL AND responded_by_membership_id IS NULL " \
                         "AND responded_at IS NULL AND resolved_by_id IS NULL AND resolved_at IS NULL) OR " \
                         "(state = 'responded' AND btrim(response) <> '' AND responded_by_membership_id IS NOT NULL " \
                         "AND responded_at IS NOT NULL AND resolved_by_id IS NULL AND resolved_at IS NULL) OR " \
                         "(state = 'resolved' AND btrim(response) <> '' AND responded_by_membership_id IS NOT NULL " \
                         "AND responded_at IS NOT NULL AND resolved_by_id IS NOT NULL AND resolved_at IS NOT NULL)",
                         name: "clarification_requests_lifecycle_check"

    create_table :clarification_evidences do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :clarification_request, null: false
      t.references :evidence, null: false

      t.timestamps
    end
    add_index :clarification_evidences, %i[clarification_request_id evidence_id], unique: true,
              name: "index_clarification_evidences_on_request_and_evidence"
    add_foreign_key :clarification_evidences, :clarification_requests,
                    column: %i[clarification_request_id organization_id],
                    primary_key: %i[id organization_id]
    add_foreign_key :clarification_evidences, :evidences,
                    column: %i[evidence_id organization_id], primary_key: %i[id organization_id]
  end

  private

  def quoted(values)
    values.map { |value| quote(value) }.join(", ")
  end
end
