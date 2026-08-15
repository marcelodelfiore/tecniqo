require "rails_helper"

RSpec.describe Assignment do
  def membership_with_role(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "requires an active Technician membership from the Work Order organization" do
    work_order = create(:work_order)
    supervisor = membership_with_role("supervisor", organization: work_order.organization)
    outsider = membership_with_role("technician", organization: create(:organization))

    expect(build(:assignment, work_order: work_order, membership: supervisor)).not_to be_valid
    expect(build(:assignment, work_order: work_order, membership: outsider)).not_to be_valid
  end

  it "preserves reassignment history and one current assignment" do
    work_order = create(:work_order)
    first_technician = membership_with_role("technician", organization: work_order.organization)
    second_technician = membership_with_role("technician", organization: work_order.organization)
    actor = create(:user)

    first = work_order.assign_to!(first_technician, assigned_by: actor)
    second = work_order.assign_to!(second_technician, assigned_by: actor)

    expect(first.reload.ended_at).to be_present
    expect(second).to be_current
    expect(work_order.assignments).to contain_exactly(first, second)
    expect(work_order.reload.current_assignment).to eq(second)
  end

  it "does not add duplicate history when assigning the current Technician again" do
    assignment = create(:assignment)

    expect(assignment.work_order.assign_to!(assignment.membership, assigned_by: create(:user))).to eq(assignment)
    expect(assignment.work_order.assignments.count).to eq(1)
  end

  it "enforces a single current Assignment in PostgreSQL" do
    assignment = create(:assignment)

    duplicate = build(:assignment, work_order: assignment.work_order,
                                    organization: assignment.organization)
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces Work Order and Membership tenant ownership in PostgreSQL" do
    assignment = create(:assignment)

    expect { described_class.where(id: assignment.id).update_all(organization_id: create(:organization).id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
