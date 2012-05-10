module Bucky::TransactionImports
  class TestData
    require 'csv'

    def self.generate_kiwibank(distributor)
      CSV.open("kiwibank_test.csv", "wb") do |csv| 
        csv << ["Date"]
        
        date = 1.month.ago
        while date < 1.day.ago
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
             when 0..25
               "#{customer.first_name.first} #{customer.last_name}"
             when 26..50
               customer.name
             else
               ""
             end
      number = case rand(100)
               when 0..75
                 customer.badge
               else
                 ""
               end
      gibbrish = ["payment", "box", "veggies"].shuffle.first
      [name, number, gibbrish].shuffle.join(" ")
    end

    def self.get_amount(customer)
      price = customer.orders.active.shuffle.first.price rescue nil
      r = rand(customer.account.balance_cents.abs/100)
      case rand(100)
      when 0..50
        r
      else
        price.present? ? price : r
      end
    end
  end
end
