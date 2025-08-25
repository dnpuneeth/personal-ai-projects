class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    @total_users = User.count
    @total_documents = Document.count
    @total_revenue = calculate_total_revenue
    @monthly_revenue = calculate_monthly_revenue
    @user_growth = calculate_user_growth
    @document_processing = calculate_document_processing
    @subscription_distribution = calculate_subscription_distribution
    @referral_stats = calculate_referral_stats
  end

  private

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def calculate_total_revenue
    # Calculate total revenue from paid subscriptions
    Subscription.paid.sum do |sub|
      case sub.plan
      when 'pro'
        29 * calculate_months_since_created(sub)
      when 'enterprise'
        100 * calculate_months_since_created(sub) # Assuming $100/month for enterprise
      else
        0
      end
    end
  end

  def calculate_monthly_revenue
    # Calculate current month revenue
    current_month = Time.current.beginning_of_month
    Subscription.paid.where('created_at >= ?', current_month).sum do |sub|
      case sub.plan
      when 'pro'
        29
      when 'enterprise'
        100
      else
        0
      end
    end
  end

  def calculate_user_growth
    # User growth over the last 6 months
    6.times.map do |i|
      month = i.months.ago.beginning_of_month
      next_month = month + 1.month
      {
        month: month.strftime('%B %Y'),
        new_users: User.where('created_at >= ? AND created_at < ?', month, next_month).count,
        total_users: User.where('created_at < ?', next_month).count
      }
    end.reverse
  end

  def calculate_document_processing
    # Document processing stats
    avg_seconds = Document.completed.average(Arel.sql("EXTRACT(EPOCH FROM (updated_at - created_at))"))
    {
      total_processed: Document.completed.count,
      total_failed: Document.where(status: 'failed').count,
      avg_processing_time: avg_seconds || 0,
      documents_today: Document.where('created_at >= ?', Time.current.beginning_of_day).count
    }
  end

  def calculate_subscription_distribution
    # Subscription plan distribution
    {
      free: Subscription.where(plan: 'free').count,
      pro: Subscription.where(plan: 'pro').count,
      enterprise: Subscription.where(plan: 'enterprise').count
    }
  end

  def calculate_referral_stats
    # Referral statistics
    {
      total_referrals: Referral.count,
      successful_referrals: Referral.successful.count,
      pending_referrals: Referral.pending.count,
      conversion_rate: Referral.count > 0 ? (Referral.successful.count.to_f / Referral.count * 100).round(1) : 0
    }
  end

  def calculate_months_since_created(subscription)
    ((Time.current - subscription.created_at) / 1.month).ceil
  end
end
