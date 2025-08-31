class CostsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get user's documents to filter AI events
    user_document_ids = current_user.documents.pluck(:id)
    user_deleted_document_ids = current_user.deleted_documents.pluck(:id)

    # Get all AI events for this user (active and deleted documents)
    user_ai_events = if user_document_ids.any? && user_deleted_document_ids.any?
      AiEvent.where(
        "document_id IN (?) OR deleted_document_id IN (?)",
        user_document_ids,
        user_deleted_document_ids
      )
    elsif user_document_ids.any?
      AiEvent.where(document_id: user_document_ids)
    elsif user_deleted_document_ids.any?
      AiEvent.where(deleted_document_id: user_deleted_document_ids)
    else
      AiEvent.none
    end

    # Get total costs for this user (including deleted documents)
    @total_cost_cents = current_user.total_cost_cents
    @total_cost_dollars = @total_cost_cents / 100.0

    # Get costs by event type for this user
    @costs_by_type = user_ai_events.group(:event_type)
                                  .sum(:cost_cents)
                                  .transform_values { |cents| cents / 100.0 }

    # Get costs by model for this user
    @costs_by_model = user_ai_events.group(:model)
                                   .sum(:cost_cents)
                                   .transform_values { |cents| cents / 100.0 }

    # Get recent events with costs for this user
    @recent_events = user_ai_events.includes(:document, :deleted_document)
                                  .order(created_at: :desc)
                                  .limit(20)

    # Get monthly costs for the last 6 months for this user
    @monthly_costs = user_ai_events.where('created_at >= ?', 6.months.ago)
                                  .group("DATE_TRUNC('month', created_at)")
                                  .sum(:cost_cents)
                                  .transform_values { |cents| cents / 100.0 }
                                  .sort.reverse.to_h

    # Get token usage statistics for this user (including deleted documents)
    @total_tokens = current_user.total_tokens_used
    @avg_tokens_per_event = user_ai_events.average(:tokens_used)&.round(0) || 0

    # Get cache statistics for this user
    @cache_hits = user_ai_events.where("metadata->>'cached' = 'true'").count
    @cache_misses = user_ai_events.where("metadata->>'cached' = 'false'").count
    @cache_hit_rate = @cache_misses > 0 ? (@cache_hits.to_f / (@cache_hits + @cache_misses) * 100).round(1) : 0

    # Additional user-specific statistics (including deleted documents)
    @total_documents = current_user.total_documents_count
    @active_documents = current_user.documents.count
    @deleted_documents = current_user.deleted_documents_count
    @total_ai_actions = current_user.total_ai_events_count
    @average_cost_per_action = @total_ai_actions > 0 ? (@total_cost_dollars / @total_ai_actions).round(4) : 0
    @average_cost_per_document = @total_documents > 0 ? (@total_cost_dollars / @total_documents).round(4) : 0

    # Deleted documents specific data
    @deleted_documents_cost_dollars = current_user.deleted_documents_cost_cents / 100.0
    @deleted_documents_tokens = current_user.deleted_documents_tokens

    # Cost trends and comparisons
    current_month_start = Time.current.beginning_of_month
    last_month_start = 1.month.ago.beginning_of_month

    @this_month_cost_dollars = user_ai_events.where('created_at >= ?', current_month_start)
                                            .sum(:cost_cents) / 100.0

    @last_month_cost_dollars = user_ai_events.where('created_at >= ?', last_month_start)
                                            .where('created_at < ?', current_month_start)
                                            .sum(:cost_cents) / 100.0

    # Calculate percentage change
    if @last_month_cost_dollars > 0
      @cost_change_percentage = ((@this_month_cost_dollars - @last_month_cost_dollars) / @last_month_cost_dollars * 100).round(1)
    else
      @cost_change_percentage = @this_month_cost_dollars > 0 ? 100.0 : 0.0
    end

    # Cache savings calculation (estimate based on cache hits)
    # Assuming each cache hit saves the cost of a new AI call
    @cache_savings_dollars = if @cache_hits > 0
      # Estimate savings based on average cost per action and cache hits
      estimated_savings = @cache_hits * @average_cost_per_action
      # Cap at a reasonable amount to avoid unrealistic numbers
      [estimated_savings, @total_cost_dollars * 0.3].min
    else
      0.0
    end
  end
end
