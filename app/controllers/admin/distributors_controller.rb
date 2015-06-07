class Admin::DistributorsController < Admin::ResourceController
  before_action :parameterize_name, only: [:create, :update]

  def index
    @distributors = Distributor.where("last_seen_at > ?", 6.months.ago).order("last_seen_at DESC")
    @distributors = @distributors.tagged_with(params[:tag]) if params[:tag].present?
    @hidden_distributors = Distributor.count - @distributors.count
    index!
  end

  def create
    create! do |success, _failure|
      success.html do
        Distributor::Defaults.populate_defaults(@distributor)
        redirect_to admin_root_url
      end
    end
  end

  def update
    update! do |success, _failure|
      success.html do
        redirect_to admin_root_url
      end
    end
  end

  def impersonate
    distributor = Distributor.find(params[:id])
    sign_in(distributor, bypass: true) # bypass means it won't update last logged in stats

    redirect_to distributor_root_url
  end

  def unimpersonate
    sign_out(:distributor)

    redirect_to admin_root_url
  end

  def country_setting
    @country = Country.find(params[:id])

    time_zone = ActiveSupport::TimeZone::MAPPING.find do |_, city|
      city == @country.time_zone
    end
    time_zone = time_zone.first if time_zone

    render json: {
      time_zone: time_zone,
      currency: @country.currency,
      fee: @country.default_consumer_fee_cents / 100.0
    }
  end

private

  def parameterize_name
    if params[:distributor]
      parameterized_name = Distributor.parameterize_name(params[:distributor][:parameter_name])
      params[:distributor][:parameter_name] = parameterized_name
    end
  end
end
