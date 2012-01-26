class DowncaseEmail < ActiveRecord::Migration
  def up
    Distributor.all.each do |d| 
      d.email = "#{d.email.downcase}"
      d.save
    end
    Customer.all.each do |c| 
      c.email = "#{c.email.downcase}"
      c.save
    end
  end

  def down
  end
end
