require "rails_helper"

RSpec.describe ExecutionTechnicalRecord do
  def submit(execution, actor)
    create(:execution_event, execution: execution, organization: execution.organization,
                             actor_membership: actor, event_type: "submitted")
  end

  it "requires descriptions, tenant context, participant provenance, and an editable Execution" do
    finding = create(:finding)
    finding.description = " "

    expect(finding).not_to be_valid
    expect(finding.errors).to include(:description)

    foreign = create(:membership, organization: create(:organization))
    cross_tenant = build(:finding, execution: finding.execution, organization: finding.organization,
                                   recorded_by_membership: foreign)
    expect(cross_tenant).not_to be_valid
    expect(cross_tenant.errors).to include(:recorded_by_membership)
  end

  it "defines severity as technical significance independently of Work Order priority" do
    finding = create(:finding)
    finding.severity = "cosmetic"

    expect(finding).not_to be_valid
    expect(Finding::SEVERITIES).to eq(%w[minor significant critical])
    expect(finding.execution.work_order.priority).to eq("normal")
  end

  it "stores decimal measurements and rejects incompatible quantity/unit pairs" do
    measurement = create(:measurement, quantity: "voltage", value: "397.125", unit: "V",
                                       measurement_point: "L1-L2")

    expect(measurement.reload.value).to eq(BigDecimal("397.125"))
    measurement.unit = "degC"
    expect(measurement).not_to be_valid
    expect(measurement.errors[:unit].join).to include("Voltage")
    expect(Measurement.units_for("temperature")).to eq(%w[degC])
  end

  it "enforces quantity/unit compatibility in PostgreSQL" do
    measurement = create(:measurement, quantity: "voltage", unit: "V")

    expect {
      Measurement.where(id: measurement.id).update_all(unit: "degC")
    }.to raise_error(ActiveRecord::StatementInvalid, /measurements_quantity_unit_check/)
  end

  it "accepts practical decimal material quantities but not inventory semantics" do
    material = create(:material_used, quantity: "2.5", unit: "m")

    expect(material.reload.quantity).to eq(BigDecimal("2.5"))
    expect(build(:material_used, quantity: 0)).not_to be_valid
    expect(build(:material_used, unit: "crate")).not_to be_valid
  end

  it "locks creation, editing, and deletion after submission" do
    finding = create(:finding)
    actor = finding.recorded_by_membership
    submit(finding.execution, actor)

    expect { finding.update!(description: "Rewritten history") }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(finding.destroy).to be(false)
    expect(build(:recommendation, execution: finding.execution,
                                  organization: finding.organization,
                                  recorded_by_membership: actor)).not_to be_valid
  end
end
