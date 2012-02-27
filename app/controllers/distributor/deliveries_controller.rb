#FIXME: Too much code in this controller!

require 'csv'

class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions collection: [:update_status, :master_packing_sheet, :export]
  belongs_to :distributor

  respond_to :html, :xml, except: [:update_status, :export]
  respond_to :json, except: [:master_packing_sheet, :export]
  respond_to :csv, only: :export

  NAV_START_DATE = Date.current - 2.week
  NAV_END_DATE   = Date.current + 2.week

  def index
    unless params[:date] && params[:view]
      redirect_to date_distributor_deliveries_path(current_distributor, Date.current, 'packing') and return
    end

    index! do
      @selected_date = Date.parse(params[:date])
      @route_id = params[:view].to_i

      @routes = current_distributor.routes

      @delivery_lists = DeliveryList.collect_lists(current_distributor, NAV_START_DATE, NAV_END_DATE)
      @delivery_list  = @delivery_lists.find { |delivery_list| delivery_list.date == @selected_date }
      @all_deliveries = @delivery_list.deliveries

      @packing_lists = PackingList.collect_lists(current_distributor, NAV_START_DATE, NAV_END_DATE)
      @packing_list  = @packing_lists.find  { |packing_list| packing_list.date == @selected_date }
      @all_packages  = @packing_list.packages

      if @route_id != 0
        @items = @all_deliveries.select{ |delivery| delivery.route.id == @route_id }
        @route = @routes.find(@route_id)
      else
        @items = @all_packages
        @route = @routes.first
      end
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.where(id: params[:deliveries])
    status = params[:status]

    options = {}
    options[:date] = params[:date] if params[:date]

    if Delivery.change_statuses(deliveries, status, options)
      head :ok
    else
      head :bad_request
    end
  end

  def export
    redirect_to :back and return unless params[:deliveries] || params[:packages]

    if params[:deliveries]
      deliveries = current_distributor.deliveries.where(id: params[:deliveries])
    elsif params[:packages]
      packages = current_distributor.packages.where(id: params[:packages])
      deliveries = packages.map{ |p| p.deliveries }.flatten
    end

    #NOTE: Perhaps change this to use comma and move into delivery model down the track and if not then pull out into a lib file
    csv_output = CSV.generate do |csv|
      csv << [
        'Delivery Route', 'Delivery Sequence Number', 'Delivery Pickup Point Name', 'Delivery Package Count',
        'Order Number', 'Delivery Number', 'Delivery Date', 'Customer Number', 'Customer First Name',
        'Customer Last Name', 'Customer Phone', 'New Customer', 'Delivery Address Line 1', 'Delivery Address Line 2',
        'Delivery Address Suburb', 'Delivery Address City', 'Delivery Address Postcode', 'Delivery Note',
        'Box Contents Short Description', 'Box Type', 'Box Likes', 'Box Dislikes', 'Box Extra Line Items'
      ]

      deliveries.each do |delivery|
        route    = delivery.route
        order    = delivery.order
        customer = delivery.customer
        address  = delivery.address
        box      = delivery.box

        total_package_count = delivery.order.quantity

        total_package_count.times do |index|
          package_count = "(#{index + 1} of #{total_package_count})"

          csv << [
            route.name,
            "%03d" % delivery.position,
            nil,
            package_count,
            order.id,
            delivery.id,
            delivery.date.strftime("%-d %b %Y"),
            customer.number,
            customer.first_name,
            customer.last_name,
            address.phone,
            (delivery.customer.new? ? 'NEW' : nil),
            address.address_1,
            address.address_2,
            address.suburb,
            address.city,
            address.postcode,
            address.delivery_note,
            order.string_sort_code,
            box.name,
            order.likes,
            order.dislikes,
            nil
          ]
        end
      end
    end

    if deliveries
      type = 'text/csv; charset=utf-8; header=present'

      if packages
        filename = "bucky-box-packing-list-export-#{Date.current.to_s}.csv"
      else
        filename = "bucky-box-delivery-list-export-#{Date.current.to_s}.csv"
      end

      send_data(csv_output, type: type, filename: filename)
    else
      respond_to :back
    end
  end

  def master_packing_sheet
    redirect_to :back and return unless params[:packages]

    @packages = current_distributor.packages.find(params[:packages])

    puts @packages.inspect

    @packages.each do |package|
      package.status = 'packed'
      package.packing_method = 'manual'
      package.save
    end

    render layout: 'print'
  end

  def reposition
    date = Date.parse(params[:date])
    delivery_order = params[:delivery]

    @delivery_list = current_distributor.delivery_lists.find_by_date(Date.parse(params[:date]))

    all_saved = true

    delivery_order.each_with_index do |delivery_id, index|
      delivery = current_distributor.deliveries.find(delivery_id)
      delivery.position = index + 1
      all_saved &= delivery.save
    end

    if all_saved
      head :ok
    else
      head :bad_request
    end
  end
end
