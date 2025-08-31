namespace :conversations do
  desc "Clean up expired conversations"
  task cleanup: :environment do
    puts "Cleaning up expired conversations..."

    expired_count = Conversation.expired.count
    puts "Found #{expired_count} expired conversations"

    if expired_count > 0
      Conversation.expired.find_each do |conversation|
        conversation.cleanup_expired
        print "."
      end
      puts "\nCleaned up #{expired_count} expired conversations"
    else
      puts "No expired conversations found"
    end

    puts "Conversation cleanup completed!"
  end

  desc "Show conversation statistics"
  task stats: :environment do
    puts "Conversation Statistics:"
    puts "========================"

    total = Conversation.count
    active = Conversation.active.count
    expired = Conversation.expired.count

    puts "Total conversations: #{total}"
    puts "Active conversations: #{active}"
    puts "Expired conversations: #{expired}"

    if total > 0
      puts "\nBy user type:"
      with_user = Conversation.joins(:user).count
      anonymous = Conversation.where(user: nil).count
      puts "  With user: #{with_user}"
      puts "  Anonymous: #{anonymous}"

      puts "\nBy subscription tier:"
      free_users = Conversation.joins(user: :subscription).where(subscriptions: { plan: 'free' }).count
      pro_users = Conversation.joins(user: :subscription).where(subscriptions: { plan: 'pro' }).count
      enterprise_users = Conversation.joins(user: :subscription).where(subscriptions: { plan: 'enterprise' }).count
      puts "  Free: #{free_users}"
      puts "  Pro: #{pro_users}"
      puts "  Enterprise: #{enterprise_users}"

      puts "\nMessage statistics:"
      total_messages = Message.count
      avg_messages = total_messages.to_f / total
      puts "  Total messages: #{total_messages}"
      puts "  Average messages per conversation: #{avg_messages.round(2)}"

      puts "\nCost statistics:"
      total_cost = Conversation.sum(:total_cost_cents)
      total_cost_dollars = total_cost / 100.0
      puts "  Total cost: $#{total_cost_dollars.round(4)}"
      puts "  Average cost per conversation: $#{(total_cost_dollars / total).round(4)}"
    end
  end
end
