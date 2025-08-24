#!/usr/bin/env ruby
# Test runner script for RedlineAI Minitest suite

require 'fileutils'

puts "🧪 RedlineAI Test Runner"
puts "======================"

# Set test environment
ENV['RAILS_ENV'] = 'test'

# Database setup commands
db_commands = [
  "RAILS_ENV=test bundle exec rails db:environment:set",
  "RAILS_ENV=test bundle exec rails db:drop",
  "RAILS_ENV=test bundle exec rails db:create", 
  "RAILS_ENV=test bundle exec rails db:migrate"
]

puts "\n📊 Setting up test database..."
db_commands.each do |cmd|
  puts "Running: #{cmd}"
  system(cmd)
  unless $?.success?
    puts "❌ Database setup failed at: #{cmd}"
    exit 1
  end
end

puts "✅ Test database setup complete!"

# Test commands to run
test_commands = [
  {
    name: "Model Tests",
    command: "bundle exec rails test test/models/ -v"
  },
  {
    name: "Controller Tests", 
    command: "bundle exec rails test test/controllers/ -v"
  },
  {
    name: "Job Tests",
    command: "bundle exec rails test test/jobs/ -v"
  },
  {
    name: "Integration Tests",
    command: "bundle exec rails test test/integration/ -v"
  }
]

results = {}

test_commands.each do |test_suite|
  puts "\n🔬 Running #{test_suite[:name]}..."
  puts "=" * 50
  
  success = system(test_suite[:command])
  results[test_suite[:name]] = success
  
  if success
    puts "✅ #{test_suite[:name]} passed!"
  else
    puts "❌ #{test_suite[:name]} failed!"
  end
end

puts "\n📋 Test Results Summary:"
puts "=" * 30

results.each do |suite, passed|
  status = passed ? "✅ PASS" : "❌ FAIL"
  puts "#{suite.ljust(20)} #{status}"
end

all_passed = results.values.all?
puts "\n🎯 Overall Result: #{all_passed ? '✅ ALL TESTS PASSED!' : '❌ SOME TESTS FAILED'}"

exit(all_passed ? 0 : 1)