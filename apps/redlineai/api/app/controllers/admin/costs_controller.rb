class Admin::CostsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @ai_cost_cents = AiEvent.sum(:cost_cents)
    @deleted_docs_cost_cents = DeletedDocument.sum(:total_cost_cents)
    @total_cost_cents = @ai_cost_cents + @deleted_docs_cost_cents
  end

  private

  def require_admin!
    redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end


