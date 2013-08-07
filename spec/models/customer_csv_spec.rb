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
      customer = customer_with({
        first_name:      "John",
        last_name:       "Doe",
        number:          666,
        email:           "exaaaample@example.com",
        first_name:      'Johnny'          ,
        last_name:       'Boy'   ,
        email:           'jony.boy@example.com'      ,
        account_balance: 66.34  ,
        minimum_balance: 23.12   ,
        halted:          false         ,
        discount:        0.2      ,
        sign_in_count:   7   ,
        notes:           'Likes beer'       ,
        special_order_preference: 'dislikes wine eh',
        via_webstore:    false    ,
        delivery_service:      'Franklin'     ,
        address_1:       'Casa Bucky'     ,
        address_2:       'The Stables'     ,
        suburb:          'Vic'     ,
        city:            'Welly'    ,
        postcode:        '6012'   ,
        delivery_note:   'round back eh'    ,
        mobile_phone:    '3423213423'   ,
        home_phone:      '34543'  ,
        work_phone:      '21455423' ,
        labels:          'fisherman, beers, vip'
      })
      customer.stub_chain(:orders, :active, :count).and_return(7)
      customer.stub(:next_order_occurrence_date).and_return(1.week.from_now)
      customer.stub_chain(:next_order, :box, :name).and_return("Apples")
      customer.stub(:last_paid).and_return(3.weeks.ago)
      @customers = [customer.decorate]
      @rows = CSV.parse(CustomerCSV.instance.generate(@customers))
    end

    it "exports the header into the csv" do
      @rows.first.should eq ["Customer Number", "First Name", "Last Name", "Email", "Last Paid Date", "Account Balance", "Minimum Balance", "Halted?", "Discount", "Customer Labels", "Customer Creation Date", "Customer Creation Method", "Sign In Count", "Customer Note", "Customer Packing Notes", "Delivery Service", "Address Line 1", "Address Line 2", "Suburb", "City", "Postcode", "Delivery Note", "Mobile Phone", "Home Phone", "Work Phone", "Active Orders Count", "Next Delivery Date", "Next Delivery"]
    end

    it "exports customer data into csv" do
      @rows[1].should eq ["0666", "Johnny", "Boy", "jony.boy@example.com", 3.weeks.ago.to_date.iso8601, "0.00", "0.23", "false", "0.2", "fisherman, beers, vip", @customers.first.created_at.to_date.iso8601, "Manual", "7", "Likes beer", "dislikes wine eh", "Franklin", "Casa Bucky", "The Stables", "Vic", "Welly", "6012", "dislikes wine eh", "3423213423", "34543", "21455423", "7", 1.week.from_now.to_date.iso8601, "Apples"]
    end
  end
end

