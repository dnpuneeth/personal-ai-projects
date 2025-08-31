class Subscription < ApplicationRecord
  belongs_to :user

  enum :status, { active: 'active', canceled: 'canceled', past_due: 'past_due', unpaid: 'unpaid' }
  enum :plan, { free: 'free', pro: 'pro', enterprise: 'enterprise' }

  validates :plan, presence: true
  validates :status, presence: true

  scope :active, -> { where(status: 'active') }
  scope :paid, -> { where.not(plan: 'free') }

  def active?
    status == 'active'
  end

  def paid?
    plan != 'free'
  end

  def can_process_document?
    return true if plan == 'enterprise'

    if plan == 'free'
      user.documents.where('created_at >= ?', Time.current.beginning_of_month).count < 5
    elsif plan == 'pro'
      user.documents.where('created_at >= ?', Time.current.beginning_of_month).count < 1000
    else
      false
    end
  end

  def documents_remaining_this_month
    return Float::INFINITY if plan == 'enterprise'

    used = user.documents.where('created_at >= ?', Time.current.beginning_of_month).count

    case plan
    when 'free'
      [5 - used, 0].max
    when 'pro'
      [1000 - used, 0].max
    else
      0
    end
  end

  def monthly_limit
    case plan
    when 'free'
      5
    when 'pro'
      1000
    when 'enterprise'
      Float::INFINITY
    else
      0
    end
  end

  def price
    case plan
    when 'free'
      0
    when 'pro'
      10.99
    when 'enterprise'
      30.99
    else
      0
    end
  end

  def features
    case plan
    when 'free'
      ['5 documents per month', 'Basic AI analysis', 'Standard support']
    when 'pro'
      ['1,000 documents per month', 'Advanced AI analysis', 'Priority support', 'Cost analytics']
    when 'enterprise'
      ['Unlimited documents', 'Custom AI models', 'Dedicated support', 'API access', 'Custom integrations']
    else
      []
    end
  end

  def plan_name
    case plan
    when 'free'
      'Free'
    when 'pro'
      'Professional'
    when 'enterprise'
      'Enterprise'
    else
      'Unknown'
    end
  end

  def plan_description
    case plan
    when 'free'
      'Perfect for getting started'
    when 'pro'
      'For ambitious professionals'
    when 'enterprise'
      'For top performer businesses'
    else
      'Unknown plan'
    end
  end

  def can_upgrade_to?(target_plan)
    return false if target_plan == plan

    case target_plan
    when 'pro'
      plan == 'free'
    when 'enterprise'
      plan == 'free' || plan == 'pro'
    else
      false
    end
  end

  def upgrade_path
    case plan
    when 'free'
      'pro'
    when 'pro'
      'enterprise'
    else
      nil
    end
  end
end
