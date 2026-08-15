require "rails_helper"

RSpec.describe Customer do
  it "requires a name and organization" do
    customer = described_class.new

    expect(customer).not_to be_valid
    expect(customer.errors).to be_of_kind(:name, :blank)
    expect(customer.errors).to be_of_kind(:organization, :blank)
  end

  it "keeps customer names unique within an organization, ignoring case" do
    customer = create(:customer, name: "Indústria ABC")

    duplicate = build(:customer, organization: customer.organization, name: "indústria abc")
    expect(duplicate).not_to be_valid
    expect(build(:customer, name: "Indústria ABC")).to be_valid
  end

  it "allows optional generic business and contact details" do
    customer = build(:customer, legal_name: "ABC S.A.", business_identifier: "RUC 123",
                                email: "operations@example.com", phone: "+595 21 555 0100")

    expect(customer).to be_valid
  end
end
