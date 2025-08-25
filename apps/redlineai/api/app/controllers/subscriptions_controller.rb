class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:show, :cancel, :reactivate]
  
  def index
    @subscription = current_user.subscription || current_user.create_subscription(plan: 'free', status: 'active')
    @documents_used = current_user.documents.where('created_at >= ?', Time.current.beginning_of_month).count
    @documents_remaining = @subscription.documents_remaining_this_month
  end
  
  def show
    @documents_used = current_user.documents.where('created_at >= ?', Time.current.beginning_of_month).count
    @documents_remaining = @subscription.documents_remaining_this_month
  end
  
  def upgrade
    plan = params[:plan]
    
    unless ['pro', 'enterprise'].include?(plan)
      redirect_to subscriptions_path, alert: 'Invalid plan selected'
      return
    end
    
    if plan == 'enterprise'
      # For enterprise, redirect to contact form
      redirect_to contact_path(plan: 'enterprise')
      return
    end
    
    # For Pro plan, we'll implement Stripe checkout later
    # For now, just upgrade the subscription
    if current_user.subscription&.update(plan: plan)
      redirect_to subscriptions_path, notice: "Successfully upgraded to #{plan.titleize} plan!"
    else
      redirect_to subscriptions_path, alert: 'Failed to upgrade subscription'
    end
  end
  
  def cancel
    if @subscription.update(status: 'canceled')
      redirect_to subscriptions_path, notice: 'Subscription canceled successfully'
    else
      redirect_to subscriptions_path, alert: 'Failed to cancel subscription'
    end
  end
  
  def reactivate
    if @subscription.update(status: 'active')
      redirect_to subscriptions_path, notice: 'Subscription reactivated successfully'
    else
      redirect_to subscriptions_path, alert: 'Failed to reactivate subscription'
    end
  end
  
  private
  
  def set_subscription
    @subscription = current_user.subscription
    redirect_to subscriptions_path, alert: 'No subscription found' unless @subscription
  end
end
