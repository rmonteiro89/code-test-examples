require 'test_helper'

class ShopTest < ActiveSupport::TestCase
  test 'cannot delete with stamps' do
    shop = FactoryGirl.build(:shop_with_stamps)
    shop.destroy
    assert shop.errors.present?
  end

  test 'validate name presence' do
    shop = FactoryGirl.build(:shop, name: nil)
    shop.valid?
    assert shop.errors.include?(:name)
  end

  test 'validate address presence' do
    shop = FactoryGirl.build(:shop, address: nil)
    shop.valid?
    assert shop.errors.include?(:address)
  end

  test 'validate maximum point presence' do
    shop = FactoryGirl.build(:shop, maximum_point: nil)
    shop.valid?
    assert shop.errors.include?(:maximum_point)
  end

  test 'validate logo presence' do
    shop = FactoryGirl.build(:shop)
    shop.logo = nil
    shop.valid?
    assert shop.errors.include?(:logo)
  end

  test 'validate maximum point divisible by ten' do
    shop = FactoryGirl.build(:shop, maximum_point: 5)
    shop.valid?
    assert shop.errors.include?(:maximum_point)
  end

  test '#open? returns true when shop does not have any opening hours' do
    shop = FactoryGirl.build(:shop)

    assert shop.open?
  end

  test '#open? returns false when shop has opening hours but it is closed' do
    shop = FactoryGirl.create(:shop)
    shop.opening_hours.create(week_day: 1, begin_at: 9, end_at: 18)
    closed_time = DateTime.new(2016, 7, 10, 0, 0, 0).utc

    assert shop.open?(closed_time) == false
  end

  test '#open? returns true when shop has opening hours and it is opened' do
    shop = FactoryGirl.create(:shop)
    shop.opening_hours.create(week_day: 1, begin_at: 9, end_at: 18)
    closed_time = DateTime.new(2016, 7, 11, 9, 30, 0).utc

    assert shop.open?(closed_time) == true
  end

  test '#validate_activity returns nil when activity is invalid' do
    invalid_activity = FactoryGirl.build(:activity)
    shop = FactoryGirl.build(:shop)

    result = shop.validate_activity(invalid_activity)

    assert result.nil?
  end

  test '#validate_opening_hours add error in activity if shop is closed' do
    shop = FactoryGirl.create(:shop)
    shop.opening_hours.create(week_day: 1, begin_at: 9, end_at: 18)
    closed_time = DateTime.new(2016, 7, 10, 0, 0, 0).utc
    Timecop.freeze(closed_time)
    activity = FactoryGirl.build(:activity)

    shop.validate_opening_hours(activity)

    assert activity.errors.include?(:base)
    assert activity.errors[:base]
      .include?('Shop is closed. Verify the opening hours.')
  end

  test '#location_limit? returns true when location_limit.present? and > 0' do
    shop = Shop.new(location_limit: 1)
    assert shop.location_limit?
  end

  test '#location_limit? returns false when location_limit is nil' do
    shop = Shop.new(location_limit: nil)
    assert shop.location_limit? == false
  end

  test '#location_limit? returns false when location_limit is 0' do
    shop = Shop.new(location_limit: 0)
    assert shop.location_limit? == false
  end

  test '#distance_over_location_limit? returns true if distance between shop
        and coordinates is greater than location_limit' do
    shop = Shop.new(location_limit: 10)
    shop.address = Address.new(latitude: 0, longitude: 0)
    result = shop.distance_over_location_limit?([10, 10])

    assert result
  end

  test '#distance_over_location_limit? returns false if distance between shop
        and coordinates is less than location_limit' do
    shop = Shop.new(location_limit: 20_000)
    shop.address = Address.new(latitude: 0, longitude: 0)
    result = shop.distance_over_location_limit?([0.1, 0.1])

    assert result == false
  end

  test '#validate_location add error in activity if shop distance from activity
        coordinates is greater than location_limit' do
    shop = FactoryGirl.create(:shop, location_limit: 100)
    shop.address = Address.new(latitude: 0, longitude: 0)
    activity = FactoryGirl.build(:activity, latitude: 10, longitude: 10)

    shop.validate_location(activity)

    assert activity.errors.include?(:base)
    assert activity.errors[:base]
      .include?('Distance from shop is over location limit(100 meters)')
  end

  test '#validate_location add error in activity if location_limit is set up and
        distance from activity coordinates is greater than location_limit' do
    shop = FactoryGirl.create(:shop, location_limit: 100)
    shop.address = Address.new(latitude: 0, longitude: 0)
    activity = FactoryGirl.build(:activity, latitude: 10, longitude: 10)

    shop.validate_location(activity)

    assert activity.errors.include?(:base)
    assert activity.errors[:base]
      .include?('Distance from shop is over location limit(100 meters)')
  end

  test '#validate_location does not add error in activity if location_limit is
        set up and distance from activity coordinates is less than location_limit' do
    shop = FactoryGirl.build(:shop, location_limit: 20_000)
    shop.address = Address.new(latitude: 0, longitude: 0)
    activity = FactoryGirl.build(:activity, latitude: 0.1, longitude: 0.1)

    shop.validate_location(activity)

    assert activity.errors.empty?
  end
end
