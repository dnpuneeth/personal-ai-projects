class Admin::BillingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @subscriptions = Subscription.order(created_at: :desc).limit(200)
    @totals = {
      paid_count: Subscription.paid.count,
      pro_count: Subscription.where(plan: 'pro').count,
      enterprise_count: Subscription.where(plan: 'enterprise').count
    }
  end

  private

  def require_admin!
    redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end


