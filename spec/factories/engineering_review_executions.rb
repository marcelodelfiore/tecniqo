FactoryBot.define do
  factory :engineering_review_execution do
    organization { engineering_review.organization }
    engineering_review
    execution
  end
end
