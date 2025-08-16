class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]

  def show
    @total_documents = @user.total_documents_count
    @active_documents = @user.documents.count
    @deleted_documents_count = @user.deleted_documents_count
    @total_ai_actions = @user.total_ai_events_count
    @total_cost = @user.total_cost_cents / 100.0
    @recent_documents = @user.documents.order(created_at: :desc).limit(5)
    # Get AI events from both active and deleted documents
    user_document_ids = @user.documents.pluck(:id)
    user_deleted_document_ids = @user.deleted_documents.pluck(:id)
 
    @recent_ai_events = if user_document_ids.any? && user_deleted_document_ids.any?
      AiEvent.where(
        "document_id IN (?) OR deleted_document_id IN (?)", 
        user_document_ids, 
        user_deleted_document_ids
      ).includes(:document, :deleted_document).order(created_at: :desc).limit(10)
    elsif user_document_ids.any?
      AiEvent.where(document_id: user_document_ids).includes(:document).order(created_at: :desc).limit(10)
    elsif user_deleted_document_ids.any?
      AiEvent.where(deleted_document_id: user_deleted_document_ids).includes(:deleted_document).order(created_at: :desc).limit(10)
    else
      AiEvent.none
    end
    @deleted_documents = @user.deleted_documents.recent.limit(5)
    @deleted_documents_cost = @user.deleted_documents_cost_cents / 100.0
  end

  def edit
  end

  def update
    if @user.update(user_params)
      if user_params[:profile_picture].present?
        redirect_to profile_path, notice: 'Profile and picture updated successfully.'
      else
        redirect_to profile_path, notice: 'Profile updated successfully.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Profile update error: #{e.message}"
    @user.errors.add(:base, "An error occurred while updating your profile. Please try again.")
    render :edit, status: :unprocessable_entity
  end

  def remove_profile_picture
    @user = current_user
    if @user.profile_picture.attached?
      begin
        @user.profile_picture.purge
        redirect_to edit_profile_path, notice: 'Profile picture removed successfully.'
      rescue => e
        Rails.logger.error "Profile picture removal error: #{e.message}"
        redirect_to edit_profile_path, alert: 'Failed to remove profile picture. Please try again.'
      end
    else
      redirect_to edit_profile_path, alert: 'No profile picture to remove.'
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :email, :profile_picture)
  end
end