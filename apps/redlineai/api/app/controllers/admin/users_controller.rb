class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @users = User.order(created_at: :desc).limit(100)
  end

  def show
    @user = User.find(params[:id])
  end

  private

  def require_admin!
    redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end


