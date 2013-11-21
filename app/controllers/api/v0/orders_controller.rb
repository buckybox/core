class Api::V0::OrdersController < Api::V0::BaseController
  before_filter :fetch_json_body, only: :create

  def_param_group :extra do
    param :id
    param :quantity
  end

  def_param_group :order do
    param :order, Hash, "Json object representing the new order", required: true do
      param :customer_id, String, "The customer's ID. If you don't have this refer to customer API."
      param :box_id, Integer, "ID of the box", required: true
      param :extras_one_off, [ :boolean ], 'True or false determining whether the extras should match the frequency of the box (false), or be a one off (true)'
      param :extras, [ :extra ], 'Array of extras, refer to above example'
      param :substitutes, [ :id ], 'Array of integers representing box_item ids that can be substituted for exclusions'
      param :exclusions, [ :id ], 'Array of integers representing box_item ids that should be excluded'
      param :frequency, String, "Indicates how often the order should be delivered. Acceptable values are 'single', 'weekly', or 'fortnightly'"
    end
  end

  api :GET, '/orders',  "Get list of orders"
  param :customer_id, String, desc: "Customer's id. Selects orders for that customer.", required: true
  example "/orders/?customer_id=123"
  def index
    cust_id = params[:customer_id]
    if cust_id.nil?
      @orders = @distributor.orders
    else
      customer = @distributor.customers.find_by(id: cust_id)
      return unprocessable_entity(customer_id: "can't be blank") if customer.nil?
      @orders = customer.orders
    end
  end

  api :GET, '/orders/:id', "Get single order"
  param :id, Integer, desc: "Order's id"
  example "api.buckybox.com/v0/orders/12"
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
    "order": {
        "box_id": 12,
        "customer_id": 123,
        "frequency": "weekly",
        "substitutes": [
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
            "extra": { 
                "id": 11, 
                "quantity": 1
            }
          },
          {
            "extra": { 
                "id": 14, 
                "quantity": 2 
            }
          }
        ]
    }
}'
  param_group :order
  def create
    new_order = @json_body["order"] || {}
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

    frequency_white_list = %w(single weekly fortnightly)

    if customer && new_order['frequency'].in?(frequency_white_list)
      schedule_days = customer.delivery_service.schedule_rule.days
      @order.schedule_rule = ScheduleRule.recur_on( Date.today, schedule_days, new_order['frequency'].to_sym)
    else
      @order.errors.add(:frequency, "must be one of: #{frequency_white_list}")
    end

    begin
      @order.substitution_ids = new_order['substitutes']
    rescue ActiveRecord::RecordNotFound
      @order.errors.add(:substitutes, "one or more substitute id are not valid")
    end

    begin
      @order.exclusion_ids = new_order['exclusions']
    rescue ActiveRecord::RecordNotFound
      @order.errors.add(:exclusions, "one or more exclusions id are not valid")
    end

    @order.extras_one_off = new_order['extras_one_off']

    @extras = new_order['extras']
    unless @extra.nil? 
      @order.order_extras = @extras.each_with_object({}) do |extra, hash|
        id = extra["extra"]["id"]
        count = extra["extra"]["quantity"]
        hash[id] = { count: count }
      end
    end

    if @order.errors.empty? && @order.save
      @customer_id = customer.id
      render 'api/v0/orders/create', status: :created, location: api_v0_order_url(id: @order.id) and return
    else
      return unprocessable_entity @order.errors
    end
  end
end
