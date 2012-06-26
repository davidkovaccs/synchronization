
FactoryGirl.define do
  factory :synchronization, :class => Refinery::Synchronizations::Synchronization do
    sequence(:model_name) { |n| "refinery#{n}" }
    sequence(:method_name) { |n| "update" }
    sequence(:model_updated_at) { |n| Time.now.to_formatted_s(:db) }
  end
end

