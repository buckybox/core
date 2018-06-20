# FIXME: Too much code in this controller!

class Distributor::DeliveriesController < Distributor::ResourceController
  custom_actions collection: [:update_status, :master_packing_sheet, :export]

  before_action :check_setup, only: [:index]
  before_action :get_email_templates, only: [:index]

  respond_to :html, except: [:update_status, :export]
  respond_to :json, except: [:master_packing_sheet, :export]
  respond_to :csv, only: :export

  # NOTE: When this is refactored also fix the "items" ordering in the sale_csv models.
  def index
    @delivery_services = current_distributor.delivery_services

    unless params[:date] && params[:view]
      redirect_to date_distributor_deliveries_url(Date.current, 'packing') and return
    end

    index! do
      @selected_date = Date.parse(params[:date])
      @delivery_service_id = params[:view].to_i

      @date_navigation = (nav_start_date..nav_end_date).to_a
      @months          = @date_navigation.group_by(&:month)

      if @delivery_service_id.zero?
        @packing_list = current_distributor.packing_list_by_date(@selected_date)
        @all_items = @packing_list.ordered_packages
        @real_list = @all_items.first.is_a?(Package)
        @items     = @real_list ? @all_items.includes(:customer) : @all_items
        @delivery_service = @delivery_services.first
        @show_tour = current_distributor.deliveries_index_packing_intro
      else
        @delivery_list = current_distributor.delivery_list_by_date(@selected_date)
        @all_items = @delivery_list.ordered_deliveries
        @real_list = @all_items.first.is_a?(Delivery)
        @items     = @real_list ? @all_items.includes(:customer) : @all_items
        @items     = @items.select { |delivery| delivery.delivery_service_id == @delivery_service_id }
        @delivery_service = @delivery_services.find(@delivery_service_id)
        @show_tour = current_distributor.deliveries_index_deliveries_intro
      end

      # XXX: count deliveries without triggering more (slow) SQL queries
      @all_item_counts_by_delivery_service_id = @all_items.group_by do |item|
        item.delivery_service.id
      end.each_with_object({}) { |(id, items), hash| hash[id] = items.count }
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])
    status = Delivery::STATUS_TO_EVENT[params[:status]]

    if Delivery.change_statuses(deliveries, status)
      head :ok
    else
      head :bad_request
    end
  end

  def make_payment
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])

    result = if params[:reverse_payment]
      Delivery.reverse_pay_on_delivery(deliveries)
    else
      Delivery.pay_on_delivery(deliveries)
    end

    if result
      head :ok
    else
      head :bad_request
    end
  end

  def master_packing_sheet
    redirect_to :back and return unless params[:packages]

    @packages = current_distributor.packages.find(params[:packages])

    @packages.each do |package|
      package.status = 'packed'
      package.packing_method = 'manual'
      package.save!
    end

    @date = @packages.first.packing_list.date

    render layout: 'print'
  end

  def reposition
    delivery_list = current_distributor.delivery_lists.find_by_date(params[:date])

    if delivery_list.reposition(params[:delivery])
      head :ok
    else
      head :bad_request
    end
  end

  def nav_start_date
    Date.current - Order::FORCAST_RANGE_BACK
  end

  def nav_end_date
    Date.current + Order::FORCAST_RANGE_FORWARD
  end
end
