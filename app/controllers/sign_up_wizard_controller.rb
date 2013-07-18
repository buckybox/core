class SignUpWizardController < ApplicationController
  layout 'sign_up_wizard'

  before_filter :set_cors_headers

  def form
    @country = Bucky::Geolocation.get_country(request.remote_ip)
    @country = "NZ" if @country.blank? || @country == "RD" # Reserved

    @time_zone = Bucky::Geolocation.get_time_zone(@country)

    render :form, layout: false, locals: { country: @country, time_zone: @time_zone }
  end

  def country
    country = Country.where(alpha2: params[:country]).first
    raise "Invalid country" if country.nil?

    @fields = Bucky::Geolocation.get_address_form country.alpha2
    @banks = OmniImporter.bank_deposit.where(country_id: country.id).pluck(:bank_name).uniq.sort

    render json: { address: @fields, banks: @banks }
  end

  def sign_up
    details = params[:distributor].dup

    %w(payment_direct_debit deliveries_per_week).each do |param|
      details.delete param # just use them for the follow-up email for now
    end

    # remove URL prefix
    details[:parameter_name].sub! "my.buckybox.com/webstore/", ""

    # fetch country ID from ISO code
    country = Country.where(alpha2: details.delete(:country)).first
    details[:country_id] = country.id if country

    # we can't mass-assign these attributes
    source = details.delete :source
    bank_name = details.delete :bank_name
    payment_paypal = details.delete :payment_paypal

    @distributor = Distributor.new(details)
    @distributor.tag_list.add source
    @distributor.omni_importers = OmniImporter.bank_deposit.where(bank_name: bank_name)

    if payment_paypal == "1"
      # NOTE: using hardcoded PayPal omni until we get more formats
      @distributor.omni_importers << OmniImporter.where(id: OmniImporter::PAYPAL_ID)
    end

    unless bank_name.nil?
      @distributor.errors.add(:bank_name, "can't be empty") if bank_name.empty?
    end

    if @distributor.errors.empty? && @distributor.save
      render json: nil

      send_follow_up_email

      if details[:payment_bank_deposit] == "1" && @distributor.omni_importers.bank_deposit.empty?
        send_bank_setup_email(bank_name)
      end

    else
      errors = @distributor.errors.full_messages

      # NOTE: temporary until we accept no payment types
      if @distributor.errors.has_key? :payment_cash_on_delivery
        errors.unshift "You must select Bank Deposit and/or Cash on Delivery"
      end

      render json: errors.join("<br>"), status: :unprocessable_entity
    end
  end

private

  def send_follow_up_email
    distributor = params[:distributor]

    options = {
      to: Figaro.env.team_emails,
      subject: "Sign up follow-up [#{Rails.env}]",
      body: <<-BODY
        Name: #{distributor[:name]}
        Email: #{distributor[:email]}
        Accept bank deposit: #{distributor[:payment_bank_deposit]} - #{distributor[:bank_name]}
        Accept PayPal: #{distributor[:payment_paypal]}
        Accept cash on delivery: #{distributor[:payment_cash_on_delivery]}
        Accept credit card: #{distributor[:payment_credit_card]}
        Accept direct debit: #{distributor[:payment_direct_debit]}
        Source: #{distributor[:source]}
        Deliveries per week: #{distributor[:deliveries_per_week]}

        <a href="#{impersonate_admin_distributor_url(id: @distributor.id)}">Impersonate</a>
      BODY
    }

    AdminMailer.information_email(options).deliver
  end

  def send_bank_setup_email bank_name
    DistributorMailer.bank_setup(@distributor, bank_name).deliver
  end

  def set_cors_headers
    if request.headers["HTTP_ORIGIN"]
      headers['Access-Control-Allow-Origin'] = request.headers["HTTP_ORIGIN"]
      headers['Access-Control-Allow-Credentials'] = 'true'
    end
  end
end

