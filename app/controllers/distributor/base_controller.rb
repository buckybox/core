class Distributor::BaseController < ApplicationController
  layout 'distributor'

  before_action :authenticate_distributor!
  before_action :mark_as_seen
  before_action :notifications
  before_action :distributor_setup

  skip_after_action :intercom_rails_auto_include

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
end
