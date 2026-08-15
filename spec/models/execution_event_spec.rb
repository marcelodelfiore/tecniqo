require "rails_helper"

RSpec.describe ExecutionEvent do
  def event_row(event, overrides = {})
    {
      organization_id: event.organization_id, execution_id: event.execution_id,
      actor_membership_id: event.actor_membership_id, event_type: "arrived_at_site",
      occurred_at: Time.current, created_at: Time.current, updated_at: Time.current
    }.merge(overrides)
  end

  it "keeps occurred_at separate from persistence time and orders with a stable tie-breaker" do
    execution = create(:execution)
    membership = create(:membership, organization: execution.organization)
    occurred_at = 1.hour.ago
    later_id = create(:execution_event, execution: execution, actor_membership: membership,
                                        event_type: "arrived_at_site", occurred_at: occurred_at)
    earlier_id = create(:execution_event, execution: execution, actor_membership: membership,
                                          event_type: "started_asset_work", occurred_at: occurred_at)

    expect(execution.execution_events.chronological).to eq([ later_id, earlier_id ])
    expect(later_id.created_at).to be > later_id.occurred_at
  end

  it "is append-oriented and rejects updates and deletion" do
    event = create(:execution_event)

    expect { event.update(event_type: "submitted") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(event.destroy).to be(false)
    expect(described_class.exists?(event.id)).to be(true)
  end

  it "constrains event and pause reason vocabulary in PostgreSQL" do
    event = create(:execution_event)

    expect {
      described_class.insert_all!([ event_row(event, event_type: "custom") ])
    }.to raise_error(ActiveRecord::StatementInvalid)
    expect {
      described_class.insert_all!([ event_row(event, event_type: "started_asset_work", reason: "break") ])
    }
      .to raise_error(ActiveRecord::StatementInvalid)
  end
end
