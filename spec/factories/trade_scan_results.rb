FactoryBot.define do
  factory :trade_scan_result do
    user { nil }
    scan_timestamp { "2025-07-29 21:18:32" }
    trades_found { 1 }
    scan_data { "MyText" }
  end
end
