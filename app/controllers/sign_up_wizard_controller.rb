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

    @fields = Bucky::Geolocation.get_address_form country.alpha2, Distributor.new
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
    country = Country.find_by(alpha2: details.delete(:country))
    details[:country_id] = country.id

    # we can't mass-assign these attributes
    source = details.delete :source
    bank_name = details.delete :bank_name
    payment_paypal = details.delete :payment_paypal

    @distributor = Distributor.new(details)
    @distributor.tag_list.add source
    @distributor.omni_importers = OmniImporter.bank_deposit.where(
      country_id: country.id, bank_name: bank_name
    )

    if payment_paypal.to_bool
      # NOTE: using hardcoded PayPal omni until we get more formats
      @distributor.omni_importers << OmniImporter.where(id: OmniImporter::PAYPAL_ID)
    end

    unless bank_name.nil?
      @distributor.errors.add(:bank_name, "can't be empty") if bank_name.empty?
    end

    if @distributor.errors.empty? && @distributor.save
      render json: nil

      send_follow_up_email

      if details[:payment_bank_deposit].to_bool && @distributor.omni_importers.bank_deposit.empty?
        send_bank_setup_email(bank_name)
      end

      Distributor::Defaults.populate_defaults(@distributor)
    else
      errors = @distributor.errors.full_messages

      # NOTE: temporary until we accept no payment types
      if @distributor.errors.has_key? :payment_cash_on_delivery
        errors.unshift "You must select Bank Deposit and/or Cash on Delivery"
      end

      render json: errors.first, status: :unprocessable_entity
    end
  end

private

  def send_follow_up_email
    distributor = params[:distributor]

    options = {
      to: Figaro.env.signups_email,
      subject: "Sign up follow-up [#{Rails.env}]",
      body: <<-BODY
        Organisation name: #{distributor[:name]}
        Email: #{distributor[:email]}
        Contact name: #{distributor[:contact_name]}
        Accept bank deposit: #{distributor[:payment_bank_deposit]} - #{distributor[:bank_name]}
        Accept PayPal: #{distributor[:payment_paypal]}
        Accept cash on delivery: #{distributor[:payment_cash_on_delivery]}
        Accept credit card: #{distributor[:payment_credit_card]}
        Accept direct debit: #{distributor[:payment_direct_debit]}
        Source: #{distributor[:source]}
        Deliveries per week: #{distributor[:deliveries_per_week]}
        Country: #{distributor[:country]}

        #{view_context.link_to "Impersonate", impersonate_admin_distributor_url(id: @distributor.id)}
        #{view_context.mail_to distributor[:email], "Email", subject: "Following up", body: "Hi #{distributor[:name]}"}
      BODY
    }

    AdminMailer.information_email(options).deliver
  end

  def send_bank_setup_email bank_name
    DistributorMailer.delay(
      run_at: 5.minutes.from_now
    ).bank_setup(@distributor, bank_name)
  end

  def set_cors_headers
    origin = request.headers["HTTP_ORIGIN"]

    if origin && origin =~ /^https?:\/\/.*\.buckybox\.com$/
      headers['Access-Control-Allow-Origin'] = origin
      headers['Access-Control-Allow-Credentials'] = 'true'
    end
  end
end

