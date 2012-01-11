class ApplicationController < ActionController::Base
  protect_from_forgery

  if Rails.env.production?
    analytical :modules=>[:google, :kiss_metrics], :use_session_store=>true
  else
    analytical :modules=>[], :use_session_store=>true
  end
end
