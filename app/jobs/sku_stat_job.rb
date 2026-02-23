class SkuStatJob < ApplicationJob
  queue_as :orders

  # Sidekiq options
  sidekiq_options retry: 3, dead: false

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order  # order deleted before job ran — nothing to do
    
    order.freeze!

    Rails.logger.info "[FreezeOrderJob] Order ##{order_id} is now frozen (editable_until: #{order.editable_until})"
  end
end
