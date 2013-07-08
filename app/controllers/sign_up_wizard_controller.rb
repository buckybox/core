class SignUpWizardController < ApplicationController
  layout 'sign_up_wizard'

  def form
    country = Bucky::Geolocation.get_country(request.remote_ip)
    country = "NZ" if country.blank? || country == "RD" # Reserved

    time_zone = Bucky::Geolocation.get_time_zone(country)

    render :form, locals: { country: country, time_zone: time_zone }
  end

  def country
    country = Country.where(alpha2: params[:country]).first

    fields = Bucky::Geolocation.get_address_form country.alpha2
    banks = OmniImporter.where(payment_type: "Bank Deposit", country_id: country.id).pluck(:name).sort
    banks << "Other"

    render json: { address: fields, banks: banks }
  end

  def sign_up
    details = params[:distributor].dup

    %w(payment_direct_debit bank_name).each do |param|
      details.delete param # just send a follow up email for now
    end

    # fetch country ID from ISO code
    country = Country.where(alpha2: details.delete(:country)).first
    details[:country_id] = country.id if country

    source = details.delete :source # store the source as a tag

    @distributor = Distributor.new(details)

    if @distributor.save
      @distributor.tag_list.add source
      @distributor.save!

      render json: nil
      send_follow_up_email
      send_welcome_email

    else
      render json: @distributor.errors.full_messages.join("<br>"),
             status: :unprocessable_entity
    end
  end

private

  def send_follow_up_email
    distributor = params[:distributor]

    options = {
      to: Figaro.env.team_emails,
      subject: "Sign up follow-up",
      body: <<-BODY
        Name: #{distributor[:name]}
        Email: #{distributor[:email]}
        Accept bank deposit: #{distributor[:payment_bank_deposit]} - #{distributor[:bank_name]}
        Accept cash on delivery: #{distributor[:payment_cash_on_delivery]}
        Accept credit card: #{distributor[:payment_credit_card]}
        Accept direct debit: #{distributor[:payment_direct_debit]}

        <a href="#{impersonate_admin_distributor_url(id: @distributor.id)}">Impersonate</a>
      BODY
    }

    AdminMailer.information_email(options).deliver
  end

  def send_welcome_email
    DistributorMailer.welcome(@distributor).deliver
  end
end

