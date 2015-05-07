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
            name: 'yoda', fee: '34', schedule_rule_attributes: { mon: '1', tue: '1', wed: '0', thu: '0',
                                                                 fri: '0', sat: '0', sun: '0' }, instructions: 'instructions'
          }
        }
      end

      specify { expect(flash[:notice]).to eq('Your new delivery service has been created.') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        @delivery_service = Fabricate(:delivery_service, distributor: @distributor, schedule_rule_attributes: { tue: true })
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: { tue: '1' } }
      end

      specify { expect(flash[:notice]).to eq('Your delivery service has been updated.') }
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
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: { mon: '0', tue: '0', wed: '0', thu: '1', fri: '0', sat: '0', sun: '0' } }
        expect(@order.reload).to be_inactive
        expect(@delivery_service.reload.schedule_rule.days).to eq [:thu]
      end

      it "removes days on order which have been removed from delivery service" do
        put :update, delivery_service: { id: @delivery_service.id, schedule_rule_attributes: { mon: '0', tue: '1', wed: '1', thu: '1', fri: '1', sat: '0', sun: '0' } }
        expect(@order.reload.schedule_rule.days).to match_array [:tue, :wed, :fri]
        expect(@order).to be_active
        expect(@delivery_service.reload.schedule_rule.days).to match_array [:tue, :wed, :thu, :fri]
      end
    end
  end
end
