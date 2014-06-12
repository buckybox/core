require 'spec_helper'

describe Distributor::Settings::DeliveryServicesController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          delivery_service: {
            name: 'yoda', fee: '34', schedule_rule_attributes: {mon: '1', tue: '1', wed: '0', thu: '0',
            fri: '0', sat: '0', sun: '0'}, instructions: 'instructions'
          }
        }
      end

      specify { flash[:notice].should eq('Your new delivery service has heen created.') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        @delivery_service = Fabricate(:delivery_service, distributor: @distributor, schedule_rule_attributes: {tue: true})
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: {tue: '1' } }
      end

      specify { flash[:notice].should eq('Your delivery service has heen updated.') }
    end

    context "with attached orders" do
      before do
        @delivery_service = Fabricate(:delivery_service,
                                        distributor: @distributor,
                                        schedule_rule:
                                          Fabricate(:schedule_rule_weekly, thu: false)
                                     )
        @order = Fabricate(:recurring_order,
                            schedule_rule:
                              Fabricate(:schedule_rule_weekly, thu: false),
                            account:
                              Fabricate(:customer,
                                        distributor: @delivery_service.distributor,
                                        delivery_service: @delivery_service
                                        ).account
                         )
      end

      it "deactivates linked orders" do
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: {mon: '0', tue: '0', wed: '0', thu: '1', fri: '0', sat: '0', sun: '0' } }
        @order.reload.should be_inactive
        @delivery_service.reload.schedule_rule.days.should eq [:thu]
      end

      it "removes days on order which have been removed from delivery service" do
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: {mon: '0', tue: '1', wed: '1', thu: '1', fri: '1', sat: '0', sun: '0' } }
        @order.reload.schedule_rule.days.should match_array [:tue, :wed, :fri]
        @order.should be_active
        @delivery_service.reload.schedule_rule.days.should match_array [:tue, :wed, :thu, :fri]
      end
    end
  end
end

