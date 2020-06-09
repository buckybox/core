class Distributor::BaseController < ApplicationController
  layout 'distributor'

  before_action :authenticate_distributor!
  before_action :mark_as_seen
  before_action :notifications
  before_action :distributor_setup
  before_action :check_if_overdue

private

  def mark_as_seen
    Distributor.mark_as_seen!(current_distributor, no_track: current_admin.present?)
  end

  def notifications
    @notifications ||= Event.all_for_distributor(current_distributor)
  end

  def distributor_setup
    @distributor_setup ||= Distributor::Setup.new(current_distributor)
  end

  def check_setup
    redirect_to distributor_root_url and return unless distributor_setup.finished_settings?
  end

  def check_if_overdue
    if current_distributor.overdue.present? && request.path != distributor_billing_path
      redirect_to distributor_billing_path and return
    end
  end
end
