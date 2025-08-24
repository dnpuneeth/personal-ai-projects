FactoryBot.define do
  factory :deleted_document do
    user { nil }
    original_document_id { 1 }
    title { "MyString" }
    file_type { "MyString" }
    page_count { 1 }
    chunk_count { 1 }
    total_cost_cents { 1 }
    total_tokens_used { 1 }
    ai_events_count { 1 }
    deleted_at { "2025-08-07 00:09:32" }
  end
end
