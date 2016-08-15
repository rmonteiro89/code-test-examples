require 'test_helper'

class CardTest < ActiveSupport::TestCase
  test 'card is locked when point is equal max point' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop_with_stamps, maximum_point: 10)
    stamp = shop.stamps.first
    stamp.point = 10
    card = client.cards.create(shop: shop)

    card.add_point(stamp)

    assert card.locked?
  end

  test 'max point is zero when shop is nil' do
    card = Card.new

    assert card.max_point.zero?
  end

  test 'progression is zero when card is new and has no bonus point' do
    card = Card.new(bonus_point: 0)

    assert card.progression.zero?
  end

  test 'progression is 100 when point is equal max point' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop_with_stamps, maximum_point: 10)
    stamp = shop.stamps.first
    stamp.point = 10
    card = client.cards.create(shop: shop)

    card.add_point(stamp)

    assert card.progression == 100
  end

  test 'uniqueness of card unlocked is not valid for same shop with the same client' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop)
    FactoryGirl.create(:card, client: client, shop: shop, locked: false)

    other_card = Card.create(client: client, shop: shop, locked: false)

    assert other_card.errors.include?(:shop)
  end

  test 'point is the sum of all the activities point + bonus point' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop, maximum_point: 20)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant, point: 10)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false, bonus_point: 5)

    card.add_point(stamp)

    assert card.point == 15
  end

  test 'point is equal max point if total activities point + bonus_point is greater than max_point' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop, maximum_point: 20)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant, point: 30)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false, bonus_point: 5)

    card.add_point(stamp)

    assert card.point == card.max_point
  end

  test 'add point generate a new card with bonus point equal the extra point' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop, maximum_point: 20)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant, point: 30)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false, bonus_point: 5)

    card.add_point(stamp)

    assert client.cards.size == 2
    new_card = client.cards.last
    assert new_card.bonus_point == card.extra_point
    assert new_card.point == new_card.bonus_point
  end

  test 'add point returns activity not saved with error if card is locked' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: true)

    activity = card.add_point(stamp)

    assert activity.persisted? == false
    assert activity.errors.include?(:card)
  end

  test 'add point returns the new activity if card is valid' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false)

    result = card.add_point(stamp)

    assert result.is_a? Activity
  end

  test 'cannot add point if shop is not open' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false)
    shop.opening_hours.create(week_day: 1, begin_at: 9, end_at: 18)
    closed_time = DateTime.new(2016, 7, 10, 0, 0, 0).utc
    Timecop.freeze(closed_time)

    activity = card.add_point(stamp)

    assert activity.errors.include?(:base)
    assert card.activities.count == 0
  end

  test 'cannot add point if distance from shop is
        greater than shop location limit' do
    client = FactoryGirl.create(:client)
    shop = FactoryGirl.create(:shop, location_limit: 100)
    shop.address.update_attributes(longitude: 0, latitude: 0)
    stamp = FactoryGirl.create(:stamp, shop: shop, merchant: shop.merchant)
    card = FactoryGirl.create(:card, client: client, shop: shop, locked: false)

    activity = card.add_point(stamp, latitude: 10, longitude: 10)

    assert activity.errors.include?(:base)
    assert card.activities.count == 0
  end
end
