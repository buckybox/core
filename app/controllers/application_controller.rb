class ApplicationController < ActionController::Base
  protect_from_forgery

  unless Rails.env.development?
    analytical :modules=>[:google, :kiss_metrics], :use_session_store=>true
  else
    analytical :modules=>[], :use_session_store=>true
  end
end
