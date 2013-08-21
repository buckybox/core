class CustomerAccountHistoryCsv
  include Singleton

  def self.generate(date, distributor)
    instance.generate(date.to_date, distributor.customers.ordered)
  end

  def generate(date, customers)
    CSV.generate do |csv|
      headers(csv)
      customers.each do |customer|
        balance = customer.balance_at(date)
        csv << [date.iso8601, customer.formated_number, customer.first_name, customer.last_name, customer.email, balance]
      end
    end
  end

  def headers(csv)
    csv << ["date", "customer number", "customer first name", "customer last name", "customer email", "customer account balance"]
  end
end
