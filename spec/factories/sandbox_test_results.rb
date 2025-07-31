FactoryBot.define do
  factory :sandbox_test_result do
    user { nil }
    test_timestamp { "2025-07-30 06:51:43" }
    total_tests { 1 }
    passed_tests { 1 }
    failed_tests { 1 }
    success_rate { "9.99" }
    test_data { "MyText" }
  end
end
