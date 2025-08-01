class SandboxTestJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    Rails.logger.info "[SandboxTestJob] Starting sandbox tests for user #{user.id}"

    # Run the full test suite
    test_service = SandboxTestService.new(user: user)
    results = test_service.run_full_test_suite

    # Store the results
    test_result = SandboxTestResult.create!(
      user: user,
      test_timestamp: results[:timestamp],
      total_tests: results[:summary][:total_tests],
      passed_tests: results[:summary][:passed_tests],
      failed_tests: results[:summary][:failed_tests],
      success_rate: results[:summary][:success_rate],
      test_data: results.to_json
    )

    Rails.logger.info "[SandboxTestJob] Test completed with #{results[:summary][:success_rate]}% success rate"
    Rails.logger.info "[SandboxTestJob] Results stored as SandboxTestResult ##{test_result.id}"

    # Log detailed results for debugging
    results[:tests].each do |test_name, test_result|
      status_emoji = test_result[:status] == "PASS" ? "✅" : "❌"
      Rails.logger.info "[SandboxTestJob] #{status_emoji} #{test_name.to_s.humanize}: #{test_result[:message]}"
    end

  rescue => e
    Rails.logger.error "[SandboxTestJob] Test suite failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Store failure result
    SandboxTestResult.create!(
      user: user,
      test_timestamp: Time.current,
      total_tests: 0,
      passed_tests: 0,
      failed_tests: 1,
      success_rate: 0.0,
      test_data: {
        error: e.message,
        backtrace: e.backtrace.first(10)
      }.to_json
    )

    raise e
  end
end
