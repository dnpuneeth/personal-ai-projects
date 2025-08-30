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
    if request.get?
      # GET request - show upgrade confirmation page
      @plan = params[:plan]
      unless ['pro', 'enterprise'].include?(@plan)
        redirect_to subscription_path, alert: 'Invalid plan selected'
        return
      end
      render :upgrade
    else
      # POST request - process the upgrade
      plan = params[:plan]

      unless ['pro', 'enterprise'].include?(plan)
        redirect_to subscription_path, alert: 'Invalid plan selected'
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
        redirect_to subscription_path, notice: "Successfully upgraded to #{plan.titleize} plan!"
      else
        redirect_to subscription_path, alert: 'Failed to upgrade subscription'
      end
    end
  end

  def cancel
    if request.get?
      # GET request - show cancel confirmation page
      render :cancel
    else
      # PATCH request - process the cancellation
      if @subscription.update(status: 'canceled')
        redirect_to subscription_path, notice: 'Subscription canceled successfully'
      else
        redirect_to subscription_path, alert: 'Failed to cancel subscription'
      end
    end
  end

  def reactivate
    if request.get?
      # GET request - show reactivate confirmation page
      render :reactivate
    else
      # PATCH request - process the reactivation
      if @subscription.update(status: 'active')
        redirect_to subscription_path, notice: 'Subscription reactivated successfully'
      else
        redirect_to subscription_path, alert: 'Failed to reactivate subscription'
      end
    end
  end

  private

  def set_subscription
    @subscription = current_user.subscription
    redirect_to subscription_path, alert: 'No subscription found' unless @subscription
  end
end
