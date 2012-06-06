module Bucky::TransactionImports
  class TestData
    require 'csv'

    def self.generate_kiwibank(distributor, time_ago=2.days, period=1.month)
      CSV.open("kiwibank_test.csv", "wb") do |csv| 
        csv << ["Date"]
        
        date = time_ago
        while date < (time_ago + period)
          distributor.customers.each do |customer|
            csv << [date.strftime("%d %b %Y"), get_description(customer), '', get_amount(customer)] if rand(100) > 95
          end
          if rand(100) > 80
            csv << [date.strftime("%d %b %Y"), "EFTPOS some bills or something", '', -23.45]
          end


          date += 1.day
        end
      end
    end

    def self.get_description(customer)
      name = case rand(100)
             when 0..5
               "#{customer.first_name.first} #{customer.last_name}"
             when 6..20
               customer.name
             else
               ""
             end
      number = case rand(100)
               when 0..30
                 customer.badge
               when 31..60
                 customer.number
               else
                 ""
               end
      gibbrish = ((customer.orders.active.collect{|o| o.box.name}) + ["payment", "box", "veggies", "veggies box", customer.distributor.name, "fruit box payment"]).shuffle.first
      [name, number, gibbrish].shuffle.join(rand(10) > 5 ? " " : "; ")
    end

    def self.get_amount(customer)
      price = customer.orders.active.shuffle.first.price rescue nil
      balance = customer.account.balance_cents.abs/100.0
      case rand(100)
      when 0..10
        balance
      else
        price.present? ? price : rand(200..1000) / 10.0
      end
    end
  end
end
