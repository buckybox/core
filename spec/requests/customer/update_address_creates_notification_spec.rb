require 'spec_helper'

describe "Updates address" do
  context 'as customer' do
    context 'with notify address is set to true' do
      let(:distributor){ Fabricate(:distributor_with_information, notify_address_change: true) }
      let(:customer) { customer = Fabricate(:customer, distributor: distributor) }

      before do
        @customer = customer
        customer_login
      end

      it "notifies distributor when address is updated" do
        change_address customer

        distributor_should_include_notifications distributor
      end

      it 'does not notify distributor when something other than address is updated' do
        change_first_name customer

        distributor_should_not_include_notifications distributor
      end

      it 'does not notify distributor when address is saved without update' do
        get_via_redirect customer_dashboard_path
        put_via_redirect customer_address_path, {}
        response.body.should match 'Your delivery address has been updated'


        distributor_should_not_include_notifications distributor
      end
    end

    context 'with notify address is set to false' do
      let(:distributor){ Fabricate(:distributor_with_information, notify_address_change: false) }
      let(:customer) { customer = Fabricate(:customer, distributor: distributor) }

      before do
        @customer = customer
        customer_login
      end

      it "does not notify distributor" do
        change_address customer

        distributor_should_not_include_notifications distributor
      end
    end
  end

  context 'as distributor' do
    context 'with notify address is set to true' do
      let(:distributor){ Fabricate(:distributor_with_information, notify_address_change: true) }
      let(:customer) { customer = Fabricate(:customer, distributor: distributor) }

      before do
        @distributor = distributor
        distributor_login
      end

      it "does not notify distributor" do
        clear_notifications
        change_address customer

        distributor_should_not_include_notifications
      end
    end
  end
end

def change_address(customer)
  original_suburb = customer.address.suburb
  modified_suburb = original_suburb + "_"

  get_via_redirect customer_dashboard_path
  if @last_login == :customer
    put_via_redirect customer_address_path, {address: {suburb: modified_suburb}}
    response.body.should match 'Your delivery address has been updated'
  else
    put_via_redirect distributor_customer_path(customer), {customer: {address_attributes: {suburb: modified_suburb}}}
    response.body.should match 'Customer was successfully updated.'
  end
end

def change_first_name(customer)
  original_first_name = customer.first_name
  modified_first_name = original_first_name + "_"

  @customer = customer
  customer_login
  get_via_redirect customer_dashboard_path
  put_via_redirect customer_customer_path(customer), {first_name: modified_first_name}
  response.body.should match 'Your details have successfully been updated.'
end

def distributor_should_not_include_notifications(distributor = nil)
  @distributor = distributor
  distributor_login unless distributor.nil?
  get_via_redirect distributor_root_path
  response.body.should match 'No new notifications'
  response.body.should_not match 'has updated their address'
end  

def distributor_should_include_notifications(distributor)
  @distributor = distributor
  distributor_login unless distributor.nil?
  get_via_redirect distributor_root_path
  response.body.should_not match 'No new notifications'
  response.body.should match 'has updated their address'
end

def clear_notifications
  post_via_redirect distributor_notifications_dismiss_all_path, {}, {"HTTP_REFERER" => distributor_root_path}
end
