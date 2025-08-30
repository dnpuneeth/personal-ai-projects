class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @total_users = User.count
    @total_documents = Document.count
    @subscriptions = Subscription.group(:plan).count
    @revenue_month = Subscription.paid.where('created_at >= ?', Time.current.beginning_of_month).count
  end

  private

  def require_admin!
    redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end


