require 'action_mailer'
require_relative 'form'
require 'active_model/validations'
require 'active_model/translation'
require 'active_model/naming'

class SettingsWebstoreForm < Form
  extend ActiveModel::Naming

  INTERFACE = {
    webstore_enabled: :active_webstore,
    org_banner_file: :company_logo,
    org_banner_file_cache: :company_logo_cache,
    team_photo_file: :company_team_image,
    team_photo_file_cache: :company_team_image_cache,
    sidebar_description: :sidebar_description,
    facebook: :facebook_url,
    phone: :phone
  }
  attr_reader :errors
  attr_accessor *(INTERFACE.keys)

  
  def initialize(opts)
    opts.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
    @errors = ActiveModel::Errors.new(self)
  end

  def self.for_distributor(distributor)
    SettingsWebstoreForm.new(
      SettingsWebstoreForm::INTERFACE.inject({}) { |result, element|
        result.merge(element.first => distributor.send(element.last))
      }
    )
  end

  def save(distributor)
    INTERFACE.each do |k,v|
      distributor.send("#{v.to_s}=", self.send(k))
    end

    saved = distributor.save
    set_errors(distributor.errors) unless saved
    saved
  end

  def webstore_enabled
    @webstore_enabled && errors[:webstore_enabled].blank?
  end

  def set_errors(errors)
    INTERFACE.each { |k,v|
      errors[v].each do |error|
        self.errors.add(k, error)
      end
    }
  end
end
