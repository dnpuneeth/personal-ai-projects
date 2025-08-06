class CostsController < ApplicationController
  def index
    # Get total costs
    @total_cost_cents = AiEvent.sum(:cost_cents)
    @total_cost_dollars = @total_cost_cents / 100.0
    
    # Get costs by event type
    @costs_by_type = AiEvent.group(:event_type)
                           .sum(:cost_cents)
                           .transform_values { |cents| cents / 100.0 }
    
    # Get costs by model
    @costs_by_model = AiEvent.group(:model)
                            .sum(:cost_cents)
                            .transform_values { |cents| cents / 100.0 }
    
    # Get recent events with costs
    @recent_events = AiEvent.includes(:document)
                           .order(created_at: :desc)
                           .limit(20)
    
    # Get monthly costs for the last 6 months
    @monthly_costs = AiEvent.where('created_at >= ?', 6.months.ago)
                           .group("DATE_TRUNC('month', created_at)")
                           .sum(:cost_cents)
                           .transform_values { |cents| cents / 100.0 }
                           .sort.reverse.to_h
    
    # Get token usage statistics
    @total_tokens = AiEvent.sum(:tokens_used)
    @avg_tokens_per_event = AiEvent.average(:tokens_used)&.round(0) || 0
    
    # Get cache statistics
    @cache_hits = AiEvent.where("metadata->>'cached' = 'true'").count
    @cache_misses = AiEvent.where("metadata->>'cached' = 'false'").count
    @cache_hit_rate = @cache_misses > 0 ? (@cache_hits.to_f / (@cache_hits + @cache_misses) * 100).round(1) : 0
  end
end
