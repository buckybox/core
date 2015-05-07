class Api::V1::OrdersController < Api::V1::BaseController
  before_action :fetch_json_body, only: :create

  def_param_group :extra do
    param :id
    param :quantity
  end

  def_param_group :order do
    param :order, Hash, "Json object representing the new order", required: true do
      param :customer_id, String, "The customer's ID. If you don't have this refer to customer API."
      param :box_id, Integer, "ID of the box", required: true
      param :extras_one_off, [:boolean], 'True or false determining whether the extras should match the frequency of the box (false), or be a one off (true)'
      param :extras, [:extra], 'Array of extras, refer to above example'
      param :substitutions, [:id], 'Array of integers representing box_item ids that can be substituted for exclusions'
      param :exclusions, [:id], 'Array of integers representing box_item ids that should be excluded'
      param :frequency, String, "Indicates how often the order should be delivered. Acceptable values are 'single', 'weekly', or 'fortnightly'"
    end
  end

  api :GET, '/orders',  "Get list of orders"
  param :customer_id, String, desc: "Customer's id. Selects orders for that customer.", required: true
  example "/orders/?customer_id=123"
  def index
    customer = @distributor.customers.find_by(id: params[:customer_id])
    return unprocessable_entity(customer_id: "is invalid") unless customer

    @orders = customer.orders.active
  end

  api :GET, '/orders/:id', "Get single order"
  param :id, Integer, desc: "Order's id"
  example "api.buckybox.com/v1/orders/12"
  def show
    order_id = params[:id]
    @order = @distributor.orders.find_by(id: order_id)

    return not_found if @order.nil?
    account = Account.find(@order.account_id)
    return not_found if account.nil?
    @customer_id = account.customer_id
  end

  api :POST, '/orders',  "Create a new order"
  description 'Currently all orders are quantity of 1 for only 1 box. For now, post a new order for every box and every quantity.'
  example '{
      "box_id": 12,
      "customer_id": 123,
      "frequency": "weekly",
      "substitutions": [
        23,
        54,
        3
      ],
      "exclusions": [
        17,
        98,
        345,
        7
      ],
      "extras_one_off": false,
      "extras": [
        {
          "id": 11,
          "quantity": 1
        },
        {
          "id": 14,
          "quantity": 2
        }
      ]
}'
  param_group :order
  def create
    new_order = @json_body || {}
    @order = Order.new

    if customer = @distributor.customers.find_by(id: new_order['customer_id'])
      @order.account = customer.account
    else
      @order.errors.add(:customer_id, "can't be blank")
    end

    if box = @distributor.boxes.find_by(id: new_order['box_id'])
      @order.box = box
    else
      @order.errors.add(:box_id, "can't be blank")
    end

    if frequency = new_order['frequency']
      frequency = frequency.to_sym

      if frequency == :monthly
        week = new_order['week']
        @order.errors.add(:week, "can't be blank") unless week
      end
    end

    start_date = new_order['start_date'] or @order.errors.add(:start_date, "can't be blank")
    week_days  = new_order['week_days'] or @order.errors.add(:week_days, "can't be blank")

    days = week_days && week_days.map { |index| I18n.t('date.abbr_day_names', locale: :en)[index].downcase.to_sym }

    frequency_valid = frequency.in?(%i(single weekly fortnightly monthly))
    @order.errors.add(:frequency, "is invalid") unless frequency_valid

    if start_date && days && frequency_valid
      @order.schedule_rule = ScheduleRule.recur_on(start_date, days, frequency, week || 0)
    end

    begin
      @order.excluded_line_item_ids = new_order['exclusions']
    rescue ActiveRecord::RecordNotFound
      @order.errors.add(:exclusions, "one or more exclusions ID are not valid")
    end

    begin
      @order.substituted_line_item_ids = new_order['substitutions']
    rescue ActiveRecord::RecordNotFound
      @order.errors.add(:substitutions, "one or more substitution ID are not valid")
    end

    @order.extras_one_off = new_order['extras_one_off']

    @extras = new_order['extras']
    unless @extras.nil?
      @order.order_extras = @extras.each_with_object({}) do |extra, hash|
        id = extra["id"]
        count = extra["quantity"]
        hash[id] = { count: count }
      end
    end

    unless new_order.key?('payment_method')
      @order.errors.add(:payment_method, "can't be blank")
    end

    if @order.errors.empty? && @order.save
      @order.activate!
      @order.account.update_attributes!(default_payment_method: new_order['payment_method'])
      Event.new_webstore_order(@order) if @order.account.distributor.notify_for_new_webstore_order
      customer.add_activity(:order_create, order: @order)
      send_confirmation_email(@order) if @order.account.distributor.email_customer_on_new_webstore_order

      @customer_id = customer.id
      render 'api/v1/orders/create', status: :created, location: api_v1_order_url(id: @order.id) and return
    else
      return unprocessable_entity @order.errors
    end
  end

  private def send_confirmation_email(order)
    CustomerMailer.delay(
      priority: Figaro.env.delayed_job_priority_high,
      queue: "#{__FILE__}:#{__LINE__}",
    ).order_confirmation(order)
  end
end
