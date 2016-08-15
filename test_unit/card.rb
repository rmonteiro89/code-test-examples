class Card < ApplicationRecord
  has_many :activities
  has_many :stamps, through: :activities
  belongs_to :client
  belongs_to :shop

  validates :client, :shop, presence: true
  validate :only_one_card_unlocked_for_shop_and_client, on: :create

  scope :unlocked, -> { where(locked: false) }
  scope :by_shop, -> (shop) { where(shop_id: shop.id) }
  scope :by_client, -> (client) { where(client_id: client.id) }

  def add_point(stamp, options = {})
    activity = activities.build({ stamp: stamp }.merge(options))
    shop.validate_activity(activity)

    if activity.errors.empty?
      activity.save && locked! && save
      create_new_card
    end

    activity
  end

  def create_new_card
    if locked? && extra_point?
      Card.create(bonus_point: extra_point, shop: shop, locked: false,
                  client: client)
    end
  end

  def locked!
    self.locked = true if max_point == point
  end

  def unlocked?
    !locked?
  end

  def point
    return max_point if extra_point?
    total_activities_point_with_bonus_point
  end

  def extra_point?
    extra_point > 0
  end

  def extra_point
    total_activities_point_with_bonus_point - max_point
  end

  def total_activities_point_with_bonus_point
    total_activities_point + bonus_point
  end

  def total_activities_point
    activities.inject(0) { |a, e| a + e.point }
  end

  def max_point
    shop.try(:maximum_point).to_i
  end

  def progression
    point.fdiv(max_point.nonzero? || 1) * 100
  end

  def most_recent_activity
    activities.most_recent.first
  end

  private

  def only_one_card_unlocked_for_shop_and_client
    if client.cards.where(shop: shop).unlocked.count > 0
      errors.add(:shop, 'already has one card unlocked for the same client')
    end
  end
end
