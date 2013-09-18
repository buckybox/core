require 'action_mailer'
require_relative 'form'
require 'active_model/validations'
require 'active_model/translation'

class SettingsWebstoreForm < Form
  attr_accessor :org_banner_file, :org_banner_file_cache, :team_photo_file, :team_photo_file_cache, :about_us, :details, :facebook, :phone
  
  def initialize(opts)
    self.org_banner_file = opts[:org_banner_file]
    self.org_banner_file_cache = opts[:org_banner_file_cache]
    self.team_photo_file = opts[:team_photo_file]
    self.team_photo_file_cache = opts[:team_photo_file_cache]
    self.about_us = opts[:about_us]
    self.details = opts[:details]
    self.facebook = opts[:facebook]
    self.phone = opts[:phone]
  end

  def self.for_distributor(distributor)
    SettingsWebstoreForm.new(
      org_banner_file: distributor.company_logo,
      org_banner_file_cache: distributor.company_logo_cache,
      team_photo_file: distributor.company_team_image,
      team_photo_file_cache: distributor.company_team_image_cache,
      about_us: distributor.about,
      details: distributor.details,
      facebook: distributor.facebook_url,
      phone: distributor.phone
    )
  end

  def save(distributor)
    distributor.company_logo = org_banner_file
    distributor.company_logo_cache = org_banner_file_cache
    distributor.company_team_image = team_photo_file
    distributor.company_team_image_cache = team_photo_file_cache
    distributor.about = about_us
    distributor.details = details
    distributor.facebook_url = facebook
    distributor.phone = phone
    distributor.save
  end
end
