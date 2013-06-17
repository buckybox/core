class CustomerCSV
  include Singleton

  def self.generate(distributor, customer_ids)
    instance.generate(distributor.customers.ordered.where(id: customer_ids).includes(route: {}, account: {route: {}}, next_order: {box: {}}).decorate)
  end

  def generate(customers)
    CSV.generate do |csv|
      csv << headers
      customers.each do |customer|
        csv_row = []
        fields.each do |field|
          csv_row << customer.send(field).to_s
        end
        csv << csv_row
      end
    end
  end

  def fields
     [:created_at         ,
     :formated_number     ,
     :first_name          ,
     :last_name           ,
     :email               ,
     :account_balance     ,
     :minimum_balance     ,
     :halted?             ,
     :discount            ,
     :sign_in_count       ,
     :notes               ,
     :delivery_note       ,
     :via_webstore        ,
     :route_name          ,
     :address_1           ,
     :address_2           ,
     :suburb              ,
     :city                ,
     :postcode            ,
     :delivery_note       ,
     :mobile_phone        ,
     :home_phone          ,
     :work_phone          ,
     :labels              ,
     :active_orders_count ,
     :next_delivery_date
    ]
  end

  def headers
    fields.collect{|f| f.to_s.titleize}
  end
end
