FactoryBot.define do
  factory :doc_chunk do
    document { nil }
    content { "MyText" }
    chunk_index { 1 }
    start_token { 1 }
    end_token { 1 }
  end
end
