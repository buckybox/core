#FIXME: Too much code in this controller!

require 'csv'

class Distributor::DeliveriesController < Distributor::ResourceController
  custom_actions collection: [:update_status, :master_packing_sheet, :export]

  before_filter :check_setup, only: [:index]

  respond_to :html, :xml, except: [:update_status, :export]
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
        @all_packages = @packing_list.ordered_packages

        @items     = @all_packages
        @real_list = @items.all? { |i| i.is_a?(Package) }
        @delivery_service = @delivery_services.first
        @show_tour = current_distributor.deliveries_index_packing_intro
      else
        @delivery_list  = current_distributor.delivery_list_by_date(@selected_date)
        @all_deliveries = @delivery_list.ordered_deliveries

        @items     = @all_deliveries.select{ |delivery| delivery.delivery_service_id  == @delivery_service_id }
        @real_list = @items.all? { |i| i.is_a?(Delivery) }
        @delivery_service = @delivery_services.find(@delivery_service_id)
        @show_tour = current_distributor.deliveries_index_deliveries_intro
      end
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])
    status = Delivery::STATUS_TO_EVENT[params[:status]]

    options = {}
    options[:date] = params[:date] if params[:date]

    if Delivery.change_statuses(deliveries, status)
      head :ok
    else
      head :bad_request
    end
  end

  def make_payment
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])
    result = false

    if params[:reverse_payment]
      result = Delivery.reverse_pay_on_delivery(deliveries)
    else
      result = Delivery.pay_on_delivery(deliveries)
    end

    if result
      head :ok
    else
      head :bad_request
    end
  end

  def export
    export = get_export(params)

    if export
      screen = params[:screen] # delivery or packing
      tracking.event(current_distributor, "export_#{screen}_list") unless current_admin.present?

      send_data(*export.csv)
    else
      redirect_to :back
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

    tracking.event(current_distributor, "print_packing_list") unless current_admin.present?

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

  def export_extras
    date = Date.parse(params[:export_extras][:date])
    csv_string = ExtrasCsv.generate(current_distributor, date)

    send_csv("bucky-box-extra-line-items-export-#{date.iso8601}", csv_string)
  end

  def nav_start_date
    Date.current - Order::FORCAST_RANGE_BACK
  end

  def nav_end_date
    Date.current + Order::FORCAST_RANGE_FORWARD
  end

private

  #NOTE: These methods are used to clean up the export input. When the UI gets better we should be able to remove
  # most if not all of the code.
  def get_export(args)
    found_key = find_key(args)
    csv_exporter, ids = make_sales_args(found_key, args[found_key]) if found_key
    export_args = { distributor: current_distributor, ids: ids, date: Date.parse(args[:date]), screen: args[:screen] }
    csv_exporter.new(export_args) if csv_exporter
  end

  def find_key(args)
    found_key = nil
    [:deliveries, :packages, :orders].each { |key| found_key = key if args.has_key?(key) }
    found_key
  end

  def make_sales_args(key, value)
    key = "SalesCsv::#{key.to_s.singularize.titleize.constantize}Exporter"
    key = key.constantize
    [ key, value ]
  end
end
