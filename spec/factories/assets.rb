FactoryBot.define do
  factory :asset do
    organization { site.organization }
    site
    sequence(:name) { |number| "Asset #{number}" }
    asset_type { "other" }
  end
end
