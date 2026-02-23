class Order < ApplicationRecord
  FREEZE_WINDOW = 15.minutes

  has_many :line_items, dependent: :destroy
  accepts_nested_attributes_for :line_items

  before_create :set_editable_until

  def editable?
    !locked? && placed_at.present? && Time.current < placed_at + FREEZE_WINDOW
  end

  def freeze!
    touch(:updated_at)
    touch(:locked_at)
  end

  private

  def set_editable_until
    self.placed_at = Time.current
  end
end
