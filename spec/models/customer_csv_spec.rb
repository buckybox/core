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
        via_webstore:    false    ,
        route_name:      'Franklin'     ,
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
      @customers = [customer.decorate]
                             
      @rows = CSV.parse(CustomerCSV.instance.generate(@customers))
    end

    it "exports the header into the csv" do
      @rows.first.should eq ["Created At", "Formated Number", "First Name", "Last Name", "Email", "Account Balance", "Minimum Balance", "Halted?", "Discount", "Sign In Count", "Notes", "Via Webstore", "Route Name", "Address 1", "Address 2", "Suburb", "City", "Postcode", "Delivery Note", "Mobile Phone", "Home Phone", "Work Phone", "Labels", "Active Orders Count", "Next Delivery Date"]
    end

    it "exports customer data into csv" do
      @rows[1].should eq [Date.today.iso8601, "0666", "Johnny", "Boy", "jony.boy@example.com", "0.00", "0.23", "false", "0.2", "7", "Likes beer", "false", "Franklin", "Casa Bucky", "The Stables", "Vic", "Welly", "6012", "", "3423213423", "34543", "21455423", "fisherman, beers, vip", "7", 1.week.from_now.to_date.iso8601]
    end
  end
end

