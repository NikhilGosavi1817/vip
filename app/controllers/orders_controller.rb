class OrdersController < ApplicationController
    before_action :set_order, only: %i[show update lock]
    before_action :ensure_editable!, only: %i[update]
    skip_before_action :verify_authenticity_token

    # GET /api/v1/orders/:id
    def show
        render json: order_json(@order)
    end

    # POST /api/v1/orders
    def create
        order = Order.new(order_params)

        if order.save
            order.line_items.map do |item|
                sku = SkuStat.find_by(sku: item.sku)
                sku.update(total_quantity: (sku&.total_quantity-item&.quantity))
            end

            SkuStatJob.set(wait: Order::FREEZE_WINDOW).perform_later(order.id)

            render json: order_json(order), status: :created
        else
            render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        if @order.update(order_params)
            render json: order_json(@order)
        else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def lock
        if @order.locked?
            render json: { error: "Order is already locked" }, status: :unprocessable_entity
            return
        end

        @order.lock!
        render json: order_json(@order)
    end

    private

    def set_order
        @order = Order.find(params[:id])
        rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
    end

    def ensure_editable!
        unless @order.editable?
            reason = @order.locked? ? "Order is manually locked" : "Edit window has expired (15-minute grace period is over)"
            render json: { error: reason }, status: :forbidden
        end
    end

    def order_params
        params.require(:order).permit(
            line_items_attributes: %i[sku quantity]
        )
    end

    def order_json(order)
        {
            id:                   order.id,
            locked_at:            order.locked_at,
            placed_at:            order.placed_at?,
            line_items:           order.line_items.map { |i| item_json(i) },
            created_at:           order.created_at,
            updated_at:           order.updated_at
        }
    end

    def item_json(item)
        { id: item.id, sku: item.sku, quantity: item.quantity }
    end
end
