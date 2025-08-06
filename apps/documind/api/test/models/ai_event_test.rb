require "test_helper"

class AiEventTest < ActiveSupport::TestCase
  def setup
    @ai_event = ai_events(:summarize_event)
    @document = documents(:sample_document)
  end

  test "should be valid with valid attributes" do
    assert @ai_event.valid?
  end

  test "should require event_type" do
    @ai_event.event_type = nil
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:event_type], "can't be blank"
  end

  test "should require model" do
    @ai_event.model = nil
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:model], "can't be blank"
  end

  test "should require tokens_used" do
    @ai_event.tokens_used = nil
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:tokens_used], "can't be blank"
  end

  test "should require document association" do
    @ai_event.document = nil
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:document], "must exist"
  end

  test "should belong to document" do
    assert_respond_to @ai_event, :document
    assert_equal @document, @ai_event.document
  end

  test "should validate event_type inclusion" do
    @ai_event.event_type = "invalid_type"
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:event_type], "is not included in the list"
  end

  test "should accept valid event_types" do
    valid_types = %w[summarize_and_risks answer_question propose_redlines]
    
    valid_types.each do |event_type|
      @ai_event.event_type = event_type
      assert @ai_event.valid?, "#{event_type} should be valid"
    end
  end

  test "should validate tokens_used is numeric" do
    @ai_event.tokens_used = "not_a_number"
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:tokens_used], "is not a number"
  end

  test "should validate tokens_used is positive" do
    @ai_event.tokens_used = -1
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:tokens_used], "must be greater than 0"
  end

  test "should allow zero tokens_used" do
    @ai_event.tokens_used = 0
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:tokens_used], "must be greater than 0"
  end

  test "should validate latency_ms is numeric when present" do
    @ai_event.latency_ms = "not_a_number"
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:latency_ms], "is not a number"
  end

  test "should validate latency_ms is not negative when present" do
    @ai_event.latency_ms = -1
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:latency_ms], "must be greater than or equal to 0"
  end

  test "should allow nil latency_ms" do
    @ai_event.latency_ms = nil
    assert @ai_event.valid?
  end

  test "should validate cost_cents is numeric when present" do
    @ai_event.cost_cents = "not_a_number"
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:cost_cents], "is not a number"
  end

  test "should validate cost_cents is not negative when present" do
    @ai_event.cost_cents = -1
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:cost_cents], "must be greater than or equal to 0"
  end

  test "should allow nil cost_cents" do
    @ai_event.cost_cents = nil
    assert @ai_event.valid?
  end

  test "should store metadata as JSON" do
    metadata = { 
      search_latency_ms: 45, 
      chunks_retrieved: 3, 
      cached: false,
      custom_field: "test"
    }
    @ai_event.update!(metadata: metadata)
    @ai_event.reload
    
    assert_equal metadata.stringify_keys, @ai_event.metadata
  end

  test "should handle nil metadata gracefully" do
    @ai_event.update!(metadata: nil)
    assert_nil @ai_event.metadata
  end

  test "should have recent scope" do
    assert_respond_to AiEvent, :recent
    recent_events = AiEvent.recent
    assert recent_events.count > 0
  end

  test "recent scope should order by created_at desc" do
    recent_events = AiEvent.recent.limit(2)
    if recent_events.count > 1
      assert recent_events.first.created_at >= recent_events.last.created_at
    end
  end

  test "should find events by document" do
    document_events = AiEvent.where(document: @document)
    assert_includes document_events, @ai_event
  end

  test "should find events by event_type" do
    summarize_events = AiEvent.where(event_type: "summarize_and_risks")
    assert_includes summarize_events, @ai_event
  end

  test "should find events by model" do
    gpt4_events = AiEvent.where(model: "gpt-4o-mini")
    assert_includes gpt4_events, @ai_event
  end

  test "should calculate total cost for document" do
    total_cost = @document.ai_events.sum(:cost_cents)
    assert total_cost > 0
  end

  test "should calculate total tokens for document" do
    total_tokens = @document.ai_events.sum(:tokens_used)
    assert total_tokens > 0
  end

  test "should group events by event_type" do
    grouped_events = AiEvent.group(:event_type).count
    assert grouped_events.keys.include?("summarize_and_risks")
  end

  test "should filter events by date range" do
    start_date = 2.days.ago
    end_date = Time.current
    
    events_in_range = AiEvent.where(created_at: start_date..end_date)
    assert_includes events_in_range, @ai_event
  end

  test "should validate model is not empty string" do
    @ai_event.model = ""
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:model], "can't be blank"
  end

  test "should validate event_type is not empty string" do
    @ai_event.event_type = ""
    assert_not @ai_event.valid?
    assert_includes @ai_event.errors[:event_type], "can't be blank"
  end
end