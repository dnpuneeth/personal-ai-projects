FactoryBot.define do
  factory :document do
    title { "MyString" }
    status { "MyString" }
    page_count { 1 }
    chunk_count { 1 }
    metadata { "" }
  end
end
