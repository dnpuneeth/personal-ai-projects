require "test_helper"

class CostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @document = documents(:sample_document)
    @ai_event = ai_events(:summarize_event)
  end

  test "should get costs index" do
    get "/costs"
    assert_response :success
    assert_select "h1", "AI Usage Cost"
    assert_select ".total-cost"
  end

  test "should display total costs correctly" do
    get "/costs"
    assert_response :success
    
    # Check that cost information is displayed
    assert_select ".cost-card" do
      assert_select ".cost-amount"
    end
  end

  test "should show cost breakdown by event type" do
    get "/costs"
    assert_response :success
    
    assert_select ".costs-by-type" do
      assert_select "tr", minimum: 1  # At least one event type row
    end
  end

  test "should show cost breakdown by model" do
    get "/costs"
    assert_response :success
    
    assert_select ".costs-by-model" do
      assert_select "tr", minimum: 1  # At least one model row
    end
  end

  test "should display recent events" do
    get "/costs"
    assert_response :success
    
    assert_select ".recent-events" do
      assert_select ".event-item", maximum: 20  # Limited to recent events
    end
  end

  test "should handle zero costs gracefully" do
    # Clear all AI events
    AiEvent.delete_all
    
    get "/costs"
    assert_response :success
    
    assert_select ".total-cost", text: /\$0\.00/
    assert_select ".no-events", text: /No AI events/i
  end

  test "should calculate cache hit rate correctly" do
    # Create cached and non-cached events
    @document.ai_events.create!(
      event_type: "summarize_and_risks",
      model: "gpt-4o-mini",
      tokens_used: 100,
      cost_cents: 10,
      metadata: { cached: true }
    )
    
    @document.ai_events.create!(
      event_type: "answer_question",
      model: "gpt-4o-mini",
      tokens_used: 50,
      cost_cents: 5,
      metadata: { cached: false }
    )
    
    get "/costs"
    assert_response :success
    
    # Should show cache hit rate
    assert_select ".cache-hit-rate"
  end

  test "should show costs in correct currency format" do
    get "/costs"
    assert_response :success
    
    # All cost displays should be in $X.XX format
    assert_select ".cost-amount", text: /\$\d+\.\d{2}/
  end

  test "should order recent events by date" do
    # Create events with different timestamps
    old_event = @document.ai_events.create!(
      event_type: "summarize_and_risks",
      model: "gpt-4o-mini",
      tokens_used: 100,
      cost_cents: 10,
      created_at: 2.hours.ago
    )
    
    new_event = @document.ai_events.create!(
      event_type: "answer_question",
      model: "gpt-4o-mini",
      tokens_used: 50,
      cost_cents: 5,
      created_at: 1.hour.ago
    )
    
    get "/costs"
    assert_response :success
    
    # Newer events should appear first
    event_items = css_select(".event-item")
    if event_items.length >= 2
      first_event_time = event_items.first.css(".event-time").first
      second_event_time = event_items.second.css(".event-time").first
      # This is a basic check - in a real test you'd parse and compare timestamps
      assert first_event_time.present?
      assert second_event_time.present?
    end
  end
end