FactoryBot.define do
  factory :subscription_tier do
    name { "MyString" }
    price_monthly { "9.99" }
    max_daily_trades { 1 }
    max_trading_capital { "9.99" }
    features { "MyText" }
    description { "MyText" }
    active { false }
  end
end
