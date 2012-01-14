class Distributor::OrdersController < Distributor::BaseController
  nested_belongs_to :distributor, :account
  actions :all, :except => :index

  respond_to :html, :xml, :json

  def create
    create! { [current_distributor, @account] }
  end

  def update
    update! { [current_distributor, @account] }
  end

  def destroy
    destroy! { [current_distributor, @account] }
  end
end
