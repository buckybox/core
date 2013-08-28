class Distributor::BaseController < ApplicationController

  layout 'distributor'

  before_filter :authenticate_distributor!
  before_filter :mark_as_seen
  before_filter :notifications
  before_filter :distributor_setup

  skip_after_filter :intercom_rails_auto_include

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

end
