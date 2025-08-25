class Admin::JobsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Get recent jobs from Solid Queue
    @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(20)
    @failed_jobs = SolidQueue::FailedExecution.joins(:job).order(created_at: :desc).limit(10)
    
    render json: {
      recent_jobs: @recent_jobs.map do |job|
        {
          id: job.id,
          class_name: job.class_name,
          queue_name: job.queue_name,
          arguments: job.arguments,
          created_at: job.created_at,
          scheduled_at: job.scheduled_at,
          finished_at: job.finished_at,
          status: job.finished_at ? 'completed' : 'pending'
        }
      end,
      failed_jobs: @failed_jobs.map do |failed_execution|
        {
          id: failed_execution.job.id,
          class_name: failed_execution.job.class_name,
          error: failed_execution.error,
          created_at: failed_execution.created_at
        }
      end,
      stats: {
        total_jobs: SolidQueue::Job.count,
        completed_jobs: SolidQueue::Job.where.not(finished_at: nil).count,
        pending_jobs: SolidQueue::Job.where(finished_at: nil).count,
        failed_jobs: SolidQueue::FailedExecution.count
      }
    }
  end
end
