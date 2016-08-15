class Shop < ApplicationRecord
  has_many :cards
  has_many :activities, through: :cards
  has_many :stamps
  has_many :opening_hours
  belongs_to :merchant
  belongs_to :address

  before_destroy do
    cannot_delete_with_stamps
    throw(:abort) if errors.present?
  end

  scope :by_client, -> (client) { joins(:cards).merge(Card.by_client(client)).distinct }

  has_attached_file :logo, default_url: "guava.png", styles: { medium: "300x300", thumb: "100x100" }
  validates_attachment :logo, presence: true, content_type: {content_type: ["image/jpg", "image/jpeg", "image/png"]}
  validates :merchant, :address, :name, :maximum_point, presence: true
  validates :maximum_point, numericality: { only_integer: true, greater_than: 0 }
  validate :maximum_point_must_be_divisible_by_ten

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :opening_hours, allow_destroy: true

  delegate :addr_1, :addr_2, :country, :city, :state, :zipcode, :state_code,
           :country_code, :latitude, :longitude, to: :address, allow_nil: true,
           prefix: true

  class << self
    # in meters
    def default_location_limit
      100
    end

    def time_zones
      hash = {}
      ActiveSupport::TimeZone.all.map { |t| hash[t.name] = t.to_s }
      hash
    end

    def time_zone_by_country_code(country_code)
      tzones = ActiveSupport::TimeZone.country_zones(country_code.downcase)
      tzones.first.name if tzones.present?
    end
  end

  def clients
    Client.by_shop(self)
  end

  def validate_activity(activity)
    return unless activity.valid?
    validate_location(activity)
    validate_opening_hours(activity)
  end

  def validate_location(activity)
    if location_limit? && distance_over_location_limit?(activity.coordinates)
      activity.errors.add(
        :base,
        "Distance from shop is over location limit(#{location_limit} meters)"
      )
    end
  end

  def location_limit?
    location_limit.present? && location_limit > 0
  end

  def distance_over_location_limit?(coordinates)
    distance = address.distance_to(coordinates)
    return false if distance.nil?
    distance > location_limit
  end

  def validate_opening_hours(activity)
    unless open?
      activity.errors.add(:base, 'Shop is closed. Verify the opening hours.')
    end
  end

  def open?(datetime = Time.current)
    return true if opening_hours.empty?
    datetime = datetime.in_time_zone(time_zone)
    opening_hours.select { |oh| oh.cover?(datetime) }.any?
  end

  private

  def maximum_point_must_be_divisible_by_ten
    return if maximum_point.nil?

    if (maximum_point % 10) != 0
      errors.add(:maximum_point, 'is not divisible by 10')
    end
  end

  def cannot_delete_with_stamps
    errors.add(:base, 'Cannot delete shop with stamps') if stamps.any?
  end
end
