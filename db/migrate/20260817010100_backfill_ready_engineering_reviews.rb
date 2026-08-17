class BackfillReadyEngineeringReviews < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO engineering_reviews
        (organization_id, work_order_id, state, created_at, updated_at)
      SELECT work_orders.organization_id, work_orders.id, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM work_orders
      WHERE EXISTS (
        SELECT 1 FROM executions WHERE executions.work_order_id = work_orders.id
      )
      AND NOT EXISTS (
        SELECT 1
        FROM executions
        WHERE executions.work_order_id = work_orders.id
          AND NOT EXISTS (
            SELECT 1 FROM execution_events
            WHERE execution_events.execution_id = executions.id
              AND execution_events.event_type = 'submitted'
          )
      )
      AND (
        SELECT executions.outcome
        FROM executions
        WHERE executions.work_order_id = work_orders.id
        ORDER BY executions.visit_number DESC
        LIMIT 1
      ) IS NOT NULL
      AND (
        SELECT executions.outcome
        FROM executions
        WHERE executions.work_order_id = work_orders.id
        ORDER BY executions.visit_number DESC
        LIMIT 1
      ) <> 'return_required'
      AND NOT EXISTS (
        SELECT 1 FROM engineering_reviews
        WHERE engineering_reviews.work_order_id = work_orders.id
      )
    SQL

    execute <<~SQL.squish
      INSERT INTO engineering_review_executions
        (organization_id, engineering_review_id, execution_id, created_at, updated_at)
      SELECT engineering_reviews.organization_id, engineering_reviews.id, executions.id,
             CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM engineering_reviews
      INNER JOIN executions ON executions.work_order_id = engineering_reviews.work_order_id
      WHERE EXISTS (
        SELECT 1 FROM execution_events
        WHERE execution_events.execution_id = executions.id
          AND execution_events.event_type = 'submitted'
      )
      AND NOT EXISTS (
        SELECT 1 FROM engineering_review_executions
        WHERE engineering_review_executions.engineering_review_id = engineering_reviews.id
          AND engineering_review_executions.execution_id = executions.id
      )
    SQL
  end

  def down
    # Existing reviews may have entered the business workflow; never delete them on rollback.
  end
end
