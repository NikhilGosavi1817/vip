class TestJob < ApplicationJob
  queue_as :default

  def perform(name)
    Rails.logger.info "Hello #{name}, Sidekiq is working!"
  end
end
