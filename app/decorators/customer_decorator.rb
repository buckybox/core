class CustomerDecorator < Draper::Decorator

  delegate_all
  delegate :name, to: :route, prefix: true
  delegate :address_1, :address_2, :suburb, :city, :postcode, :delivery_note, :mobile_phone, :home_phone, :work_phone, to: :address

  def account_balance
    object.account.balance
  end

  def labels
    object.tag_list.join(', ')
  end

  def active_orders_count
    object.orders.active.count
  end

  def minimum_balance
    object.balance_threshold
  end

  def delivery_note
    object.special_order_preference
  end

  def next_delivery_date
    date = object.next_order_occurrence_date
    if date
      date.to_date.iso8601
    else
      ""
    end
  end

  def created_at
    object.created_at.to_date.iso8601
  end
end

