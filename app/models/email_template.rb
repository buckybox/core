# An email template which can be personalized for a given customer
class EmailTemplate < EmailTemplator
  # white-list of special keywords to be replaced
  KEYWORDS = {
    first_name:            :first_name,
    last_name:             :last_name,
    account_balance:       :account_balance_with_currency,
    address:               :address,
    next_delivery_summary: :next_delivery_summary,
    delivery_service:      :delivery_service_name,
    customer_number:       :customer_number,
    email_address:         :email,
  }.freeze

  def pre_personalize_hook(customer)
    customer.decorate unless customer.decorated?
  end
end
