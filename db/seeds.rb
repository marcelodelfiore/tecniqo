# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
if Rails.env.development? || ENV["LOAD_DEMO_DATA"] == "true"
  organization = Organization.find_or_create_by!(name: "Técniqo Demo Maintenance")
  founder = User.find_or_create_by!(email: "founder@tecniqo.local") do |user|
    user.founder = true
  end
  founder.update!(founder: true) unless founder.founder?

  membership = Membership.find_or_create_by!(organization: organization, user: founder)
  membership.update!(active: true)
  membership.membership_roles.find_or_create_by!(role: "administrator")

  technician_user = User.find_or_create_by!(email: "joao.technician@tecniqo.local")
  technician_membership = Membership.find_or_create_by!(organization: organization, user: technician_user)
  technician_membership.update!(active: true)
  technician_membership.membership_roles.find_or_create_by!(role: "technician")

  customer = Customer.find_or_create_by!(organization: organization, name: "Indústria ABC")
  betim = Site.find_or_create_by!(organization: organization, customer: customer, name: "Betim Plant")
  contagem = Site.find_or_create_by!(organization: organization, customer: customer, name: "Contagem Plant")

  Asset.find_or_create_by!(organization: organization, site: betim, name: "Motor M-21") do |asset|
    asset.asset_type = "motor"
    asset.tag = "M-21"
    asset.manufacturer = "WEG"
  end
  Asset.find_or_create_by!(organization: organization, site: betim, name: "QGBT-01") do |asset|
    asset.asset_type = "electrical_panel"
    asset.tag = "QGBT-01"
  end
  Asset.find_or_create_by!(organization: organization, site: contagem, name: "Transformer TR-02") do |asset|
    asset.asset_type = "transformer"
    asset.tag = "TR-02"
  end

  service_type_names = [
    "Corrective Electrical Maintenance",
    "Preventive Electrical Maintenance",
    "Electrical Panel Inspection",
    "Thermographic Inspection",
    "Motor Inspection",
    "Emergency Electrical Service"
  ]
  service_type_names.each do |name|
    ServiceType.find_or_create_by!(organization: organization, name: name)
  end

  motor = Asset.find_by!(organization: organization, site: betim, name: "Motor M-21")
  corrective = ServiceType.find_by!(organization: organization, name: "Corrective Electrical Maintenance")
  requested_work = "Motor protection trips after operating for a few minutes."
  work_order = WorkOrder.find_by(organization: organization, customer: customer, site: betim,
                                 asset: motor, service_type: corrective, requested_work: requested_work)
  work_order ||= WorkOrder.issue!(
    organization: organization,
    attributes: {
      customer: customer,
      site: betim,
      asset: motor,
      service_type: corrective,
      requested_work: requested_work,
      priority: "high",
      scheduled_start: 1.week.from_now.change(hour: 8, min: 0)
    },
    created_by: founder,
    assignee_membership: technician_membership
  )
  work_order.assign_to!(technician_membership, assigned_by: founder) unless work_order.current_assignment

  unless work_order.executions.exists?
    Execution.create_for!(work_order: work_order, created_by: founder,
                          scheduled_start: work_order.scheduled_start)
  end

  execution = work_order.executions.first
  unless execution.submitted?
    technical_attributes = {
      organization: organization,
      execution: execution,
      recorded_by_membership: technician_membership
    }
    Finding.find_or_create_by!(execution: execution,
                               description: "Abnormal heating observed at contactor terminal T2.") do |record|
      record.assign_attributes(technical_attributes.merge(severity: "significant", recorded_at: Time.current))
    end
    [ [ "temperature", 87.3, "degC", "Contactor terminal T2" ],
      [ "voltage", 397, "V", "L1-L2" ] ].each do |quantity, value, unit, point|
      Measurement.find_or_create_by!(execution: execution, quantity: quantity, measurement_point: point) do |record|
        record.assign_attributes(technical_attributes.merge(value: value, unit: unit, recorded_at: Time.current))
      end
    end
    ActionPerformed.find_or_create_by!(execution: execution,
                                       description: "Damaged terminal replaced and connection retorqued.") do |record|
      record.assign_attributes(technical_attributes.merge(recorded_at: Time.current))
    end
    MaterialUsed.find_or_create_by!(execution: execution, description: "Replacement terminal") do |record|
      record.assign_attributes(technical_attributes.merge(quantity: 1, unit: "piece", recorded_at: Time.current))
    end
    Recommendation.find_or_create_by!(execution: execution,
                                      description: "Reinspect connection during next scheduled shutdown.") do |record|
      record.assign_attributes(technical_attributes.merge(recorded_at: Time.current))
    end
  end
end
