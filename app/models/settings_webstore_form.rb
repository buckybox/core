require 'action_mailer'
require_relative 'form'
require 'active_model/validations'
require 'active_model/translation'

class SettingsWebstoreForm < Form
  attr_accessor :errors, :org_banner_file, :org_banner_file_cache, :team_photo_file, :team_photo_file_cache, :sidebar_description, :facebook, :phone
  
  def initialize(opts)
    self.org_banner_file = opts[:org_banner_file]
    self.org_banner_file_cache = opts[:org_banner_file_cache]
    self.team_photo_file = opts[:team_photo_file]
    self.team_photo_file_cache = opts[:team_photo_file_cache]
    self.sidebar_description = opts[:sidebar_description]
    self.facebook = opts[:facebook]
    self.phone = opts[:phone]
  end

  def self.for_distributor(distributor)
    SettingsWebstoreForm.new(
      org_banner_file: distributor.company_logo,
      org_banner_file_cache: distributor.company_logo_cache,
      team_photo_file: distributor.company_team_image,
      team_photo_file_cache: distributor.company_team_image_cache,
      sidebar_description: distributor.sidebar_description,
      facebook: distributor.facebook_url,
      phone: distributor.phone
    )
  end

  def save(distributor)
    distributor.company_logo = org_banner_file
    distributor.company_logo_cache = org_banner_file_cache
    distributor.company_team_image = team_photo_file
    distributor.company_team_image_cache = team_photo_file_cache
    distributor.sidebar_description = sidebar_description
    distributor.facebook_url = facebook
    distributor.phone = phone
    
    saved = distributor.save
    set_errors(distributor.errors) unless saved
    saved
  end

  def set_errors(errors)
    self.errors = errors
  end
end
