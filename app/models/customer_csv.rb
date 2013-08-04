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
     [
     :customer_number          ,
     :first_name               ,
     :last_name                ,
     :email                    ,
     :last_paid_date           ,
     :account_balance          ,
     :minimum_balance          ,
     :halted?                  ,
     :discount                 ,
     :customer_labels          ,
     :customer_creation_date   ,
     :customer_creation_method ,
     :sign_in_count            ,
     :customer_note            ,
     :customer_packing_notes   ,
     :delivery_service         ,
     :address_line_1           ,
     :address_line_2           ,
     :suburb                   ,
     :city                     ,
     :postcode                 ,
     :delivery_note            ,
     :mobile_phone             ,
     :home_phone               ,
     :work_phone               ,
     :active_orders_count      ,
     :next_delivery_date       ,
     :next_delivery
    ]
  end

  def headers
    fields.collect{|f| f.to_s.titleize}
  end
end
