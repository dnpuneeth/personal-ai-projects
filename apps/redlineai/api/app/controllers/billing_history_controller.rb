class BillingHistoryController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_user.subscription
    @ai_events = current_user.ai_events.includes(:document).order(created_at: :desc).limit(50)
    @deleted_documents = current_user.deleted_documents.order(created_at: :desc).limit(50)

    # Calculate costs
    @total_ai_costs = @ai_events.sum(&:cost_dollars)
    @total_deletion_costs = @deleted_documents.sum(&:total_cost_dollars)
    @total_costs = @total_ai_costs + @total_deletion_costs

    # Group costs by month
    @monthly_costs = calculate_monthly_costs
  end

  private

  def calculate_monthly_costs
    monthly_costs = {}

        # AI events costs by month
    @ai_events.group_by { |event| event.created_at.beginning_of_month }.each do |month, events|
      monthly_costs[month] ||= { ai_costs: 0, deletion_costs: 0, total: 0 }
      monthly_costs[month][:ai_costs] = events.sum(&:cost_dollars)
    end

    # Deleted documents costs by month
    @deleted_documents.group_by { |doc| doc.created_at.beginning_of_month }.each do |month, docs|
      monthly_costs[month] ||= { ai_costs: 0, deletion_costs: 0, total: 0 }
      monthly_costs[month][:deletion_costs] = docs.sum(&:total_cost_dollars)
    end

    # Calculate totals for each month
    monthly_costs.each do |month, costs|
      costs[:total] = costs[:ai_costs] + costs[:deletion_costs]
    end

    monthly_costs.sort.reverse.to_h
  end
end
