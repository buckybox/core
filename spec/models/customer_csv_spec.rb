require 'spec_helper'

describe CustomerCSV do
  describe "#generate" do
    let(:distributor){
      mock("distributor")
    }
    it "orders and decorates the customers" do
      customers = mock("customers")
      distributor.stub_chain(:customers, :ordered, :where, :includes, :decorate).and_return(customers)
      CustomerCSV.instance.should_receive(:generate).with(customers)
      CustomerCSV.generate(distributor, [])
    end
  end

  describe ".generate" do
    
    before do
      account = Fabricate(:account, customer: Fabricate(:customer,
        first_name: "John",
        last_name: "Doe",
        number: 666,
        email: "exaaaample@example.com",
        balance_threshold_cents: 444,
        discount: 0.34,
        sign_in_count: 65,
        notes: 'Bitch, please.',
        tag_list: 'vip, pimp'),
      )
      customer = account.customer
      customer.address = Fabricate(:full_address)
      customer.save
      account.change_balance_to(666.66)
      account.reload

      customer = account.customer
      customer.stub_chain(:orders, :active, :count).and_return(7)
      customer.stub(:next_order_occurrence_date).and_return(1.week.from_now)
      decorated_customer = account.customer.decorate
      @customers = [decorated_customer]
                             
      @rows = CSV.parse(CustomerCSV.instance.generate(@customers))
    end

    it "exports the header into the csv" do
      @rows.first.should eq ["Created At", "Formated Number", "First Name", "Last Name", "Email", "Account Balance", "Minimum Balance", "Halted?", "Discount", "Sign In Count", "Notes", "Delivery Note", "Via Webstore", "Route Name", "Address 1", "Address 2", "Suburb", "City", "Postcode", "Delivery Note", "Mobile Phone", "Home Phone", "Work Phone", "Labels", "Active Orders Count", "Next Delivery Date"]
    end

    it "exports customer data into csv" do
      @rows[1].should eq [Date.today.iso8601, "0666", "John", "Doe", "exaaaample@example.com", "0.00", "4.44", "false", "0.34", "65", "Bitch, please.", "", "false", "Route 2", "5 Address St", "Apartment 1", "Suburb", "City", "00000", "", "11-111-111-1111", "22-222-222-2222", "33-333-333-3333", "pimp, vip", "7", 1.week.from_now.to_date.iso8601]
    end
  end
end

