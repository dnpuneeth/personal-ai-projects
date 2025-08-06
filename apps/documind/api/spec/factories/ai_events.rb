FactoryBot.define do
  factory :ai_event do
    document { nil }
    event_type { "MyString" }
    model { "MyString" }
    tokens_used { 1 }
    latency_ms { 1 }
    cost_cents { 1 }
    metadata { "" }
  end
end
