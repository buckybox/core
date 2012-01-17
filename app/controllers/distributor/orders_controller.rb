class Distributor::OrdersController < Distributor::BaseController
  nested_belongs_to :distributor, :account
  actions :all, :except => :index

  respond_to :html, :xml, :json

  def create
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:account_id])
    @order = Order.new(params[:order])

    frequency = params[:order][:frequency]
    start_time = Date.parse(params[:start_date]).to_time
    schedule = IceCube::Schedule.new(start_time)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time)
    else
      days_by_number = params[:days].values.map(&:to_i).sort
      weeks_between_deliveries = Order::FREQUENCY_HASH[frequency]

      recurrence_rule = IceCube::Rule.weekly(weeks_between_deliveries).day(*days_by_number)
      schedule.add_recurrence_rule(recurrence_rule)
    end

    @order.account = @account
    @order.schedule = schedule
    @order.completed = true

    create! { [current_distributor, @account] }
  end

  def update
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:account_id])
    @order = Order.find(params[:id])

    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update! { [current_distributor, @account] }
  end

  def destroy
    destroy! { [current_distributor, @account] }
  end
end
