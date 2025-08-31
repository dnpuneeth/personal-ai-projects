class Admin::CostsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @ai_cost_cents = AiEvent.sum(:cost_cents)
    @deleted_docs_cost_cents = DeletedDocument.sum(:total_cost_cents)
    @total_cost_cents = @ai_cost_cents + @deleted_docs_cost_cents

    # Enhanced analytics data
    @total_ai_events = AiEvent.count
    @total_tokens_used = AiEvent.sum(:tokens_used)
    @average_cost_per_event = @total_ai_events > 0 ? (@ai_cost_cents / 100.0 / @total_ai_events).round(4) : 0
    @average_tokens_per_event = @total_ai_events > 0 ? (@total_tokens_used.to_f / @total_ai_events).round(0) : 0

    # Cache statistics
    @cache_hits = AiEvent.where("metadata->>'cached' = 'true'").count
    @cache_misses = AiEvent.where("metadata->>'cached' = 'false'").count
    @cache_hit_rate = @total_ai_events > 0 ? (@cache_hits.to_f / @total_ai_events * 100).round(1) : 0

    # Cost trends over time
    @monthly_costs = AiEvent.where('created_at >= ?', 6.months.ago)
                           .group("DATE_TRUNC('month', created_at)")
                           .sum(:cost_cents)
                           .transform_values { |cents| cents / 100.0 }
                           .sort.reverse.to_h

    # Model usage statistics
    @costs_by_model = AiEvent.group(:model)
                             .sum(:cost_cents)
                             .transform_values { |cents| cents / 100.0 }
                             .sort_by { |_, cost| -cost }.to_h

    # Event type statistics
    @costs_by_event_type = AiEvent.group(:event_type)
                                  .sum(:cost_cents)
                                  .transform_values { |cents| cents / 100.0 }
                                  .sort_by { |_, cost| -cost }.to_h

    # User cost distribution
    @top_users_by_cost = User.joins(:documents)
                             .joins("JOIN ai_events ON ai_events.document_id = documents.id")
                             .group('users.id')
                             .select('users.*, SUM(ai_events.cost_cents) as total_cost_cents')
                             .order('total_cost_cents DESC')
                             .limit(10)

    # Recent high-cost events
    @recent_high_cost_events = AiEvent.includes(:document, :user)
                                     .order(cost_cents: :desc)
                                     .limit(10)
  end

  private

  def require_admin!
    redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end


