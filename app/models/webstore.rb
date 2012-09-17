class Webstore
  attr_reader :distributor, :order, :ip_address, :next_step

  STORE     = :store
  CUSTOMISE = :customise
  LOGIN     = :login
  DELIVERY  = :delivery
  COMPLETE  = :complete

  def initialize(distributor, session, ip_address)
    webstore_session = session[:webstore]

    if webstore_session
      @order     = WebstoreOrder.find(webstore_session[:webstore_order_id])
      @next_step = webstore_session[:next_step]
    end

    @distributor = distributor
    @ip_address  = ip_address
  end

  def to_session
    { webstore_order_id: @order.id, next_step: next_step }
  end

  def process_params(params)
    start_order(params[:box_id]) if @order.nil? && params[:box_id]

    webstore_order = params[:webstore_order]

    if webstore_order
      customise_order(webstore_order[:customise]) if webstore_order[:customise]
    end

    @order.save
  end

  def customise_order(customise)
    add_exclusions_to_order(customise[:dislikes]) if customise[:dislikes]
    add_substitutes_to_order(customise[:likes]) if customise[:likes]
    add_extras_to_order(customise[:extras]) if customise[:extras]
    @next_step = LOGIN
  end

  def add_extras_to_order(extras)
    extras.delete('add_extra')
    @webstore_order.extras = extras.select { |k,v| v.to_i > 0 }
  end

  def add_substitutes_to_order(substitutes)
    substitutes.delete('')
    @order.substitutes = substitutes
  end

  def add_exclusions_to_order(exclusions)
    exclusions.delete('')
    @order.exclusions = exclusions
  end

  def start_order(box_id)
    box = Box.where(id: box_id, distributor_id: @distributor.id).first
    @order = WebstoreOrder.create(box: box, remote_ip: @ip_address)
    @next_step = (box.customisable? ? CUSTOMISE : LOGIN)
  end
end
