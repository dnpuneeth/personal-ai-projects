namespace :ai do
  desc "Clean up expired temporary AI results"
  task cleanup_temp_results: :environment do
    expired_count = TempAiResult.expired.count
    TempAiResult.expired.delete_all
    
    puts "Cleaned up #{expired_count} expired temporary AI results"
  end
end
