def prepare_technical_record_actor(record)
  membership = record.recorded_by_membership
  record.execution.save! unless record.execution.persisted?
  membership.save! unless membership.persisted?
  create(:membership_role, membership: membership, role: "technician") unless
    membership.membership_roles.exists?(role: "technician")
  return if record.execution.participant?(membership)

  create(:execution_participant, organization: record.organization, execution: record.execution,
                                 membership: membership)
end
