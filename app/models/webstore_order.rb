class WebstoreOrder < ActiveRecord::Base
  include Bucky

  belongs_to :account
  belongs_to :box

  has_one :customer, through: :account

  has_one :distributor, through: :account

  serialize :exclusions, Array
  serialize :substitutions, Array
  serialize :extras, Hash

  schedule_for :schedule

  attr_accessible :box, :remote_ip

  STORE     = :store
  CUSTOMISE = :customise
  LOGIN     = :login
  DELIVERY  = :delivery
  COMPLETE  = :complete
  PLACED    = :placed

  def thumb_url
    box.big_thumb_url
  end

  def route
    @route_mem ||= account.route
  end

  def box_name
    box.name
  end

  def box_price
    box.price
  end

  def box_description
    box.description
  end

  def route_name
    route.name
  end

  def route_fee
    route.fee
  end

  def order_extras_price
    unless @order_extras_price_mem
      order_extra_hash = extras.map do |id, count|
        extra_object = extra_objects.find{ |extra| extra.id == id.to_i }
        {
          name: extra_object.name,
          unit: extra_object.unit,
          price_cents: extra_object.price_cents,
          currency: extra_object.currency,
          count: count
        }
      end

      @order_extras_price_mem = Package.calculated_extras_price(order_extra_hash)
    end

    return @order_extras_price_mem
  end

  def order_price
    unless @order_price_mem
      @order_price_mem = Package.calculated_individual_price(box, route)
      @order_price_mem += order_extras_price unless extras.empty?
    end

    return @order_price_mem
  end

  def completed?
    status == PLACED
  end

  def customised?
    !exclusions.empty? || !extras.empty?
  end

  def scheduled?
    !route.nil?
  end

  def customise_step
    self.status = CUSTOMISE
  end

  def login_step
    self.status = LOGIN
  end

  def delivery_step
    self.status = DELIVERY
  end

  def complete_step
    self.status = COMPLETE
  end

  def placed_step
    self.status = PLACED
  end

  def extra_objects
    @extra_objects_mem ||= Extra.find_all_by_id(extras.map(&:first))
  end

  def exclusion_objects
    @exclusion_objects_mem ||= LineItem.find_all_by_id(exclusions)
  end

  def substitution_objects
    @substitution_objects_mem ||= LineItem.find_all_by_id(substitutions)
  end

  def customisation_description
    unless @customisation_description_mem
      exclusions_string = exclusion_objects.map(&:name).join(', ')
      substitution_string = substitution_objects.map(&:name).join(', ')

      unless exclusions_string.blank?
        @customisation_description_mem = "Exclude #{exclusions_string}"
        @customisation_description_mem += "/ Substitute #{substitution_string}" unless substitution_string.blank?
      end
    end

    return @customisation_description_mem
  end

  def extras_description
    unless @extras_description_mem
      @extras_description_mem = extras.map do |id, count|
        extra_object = extra_objects.find{ |extra| extra.id == id.to_i }
        "#{count}x #{extra_object.name} #{extra_object.unit}"
      end.join(', ')

      if schedule && !schedule.frequency.single?
        @extras_description_mem += (extras_one_off? ? ', include in the next delivery only' : ', include with every delivery')
      end
    end

    return @extras_description_mem
  end
end
