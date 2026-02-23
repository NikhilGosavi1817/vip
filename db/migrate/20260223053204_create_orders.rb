class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.datetime :placed_at
      t.datetime :locked_at
      t.boolean :locked, default: false
      t.timestamps
    end
  end
end
