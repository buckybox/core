module Billing
  class PaypalInvoice
    require 'paypal-sdk-rest'

    include PayPal::SDK::REST

    PayPal::SDK.configure(
      mode: (Rails.env.production? ? "live" : "sandbox"),
      client_id: Figaro.env.paypal_api_client_id,
      client_secret: Figaro.env.paypal_api_client_secret,
    )

    PayPal::SDK.logger = Rails.logger
    PayPal::SDK.logger.level = (Rails.env.production? ? Logger::INFO : Logger::DEBUG)

    def self.create!(invoice)
      distributor = invoice.distributor
      address = distributor.localised_address

      paypal_invoice = Invoice.new(
        "merchant_info" => {
          "email" => "support@buckybox.com",
          "business_name" => "Bucky Box Limited",
          "website" => "www.buckybox.com",
          "tax_id" => "GST # 107-665-145",
          "address" => {
            "line1" => "Level 2, 89 Courtenay Place",
            "city" => "Wellington",
            "state" => "Wellington",
            "postal_code" => "6011",
            "country_code" => "NZ",
          },
        },
        "billing_info" => [
          {
            "email" => distributor.email,
            "business_name" => distributor.name,
            "address" => {
              "line1" => default_if_blank(address.street),
              "city" => default_if_blank(address.city),
              "state" => default_if_blank(address.state),
              "postal_code" => default_if_blank(address.zip),
              "country_code" => address.country,
            },
          },
        ],
        "items" => [
          {
            "name" => invoice.description,
            "quantity" => 1,
            "unit_price" => {
              "currency" => invoice.currency,
              "value" => invoice.amount.to_s,
            },
          },
        ],
        "note" => "From #{invoice.from} to #{invoice.to}",
        "payment_term" => {
          "term_type" => "NET_30",
        }
      )

      if paypal_invoice.create
        Rails.logger.info "Invoice[#{paypal_invoice.id}] created successfully"

        if paypal_invoice.send_invoice
          Rails.logger.info "Invoice[#{paypal_invoice.id}] sent successfully"
        else
          Bugsnag.notify(RuntimeError.new(paypal_invoice.error.inspect))
        end
      else
        Bugsnag.notify(RuntimeError.new(paypal_invoice.error.inspect))
      end

      paypal_invoice.number
    end

    def self.overdue_invoices(email)
      query = Invoice.search(email: email, status: ["SENT"])

      query.invoices.select do |invoice|
        due_date = invoice.payment_term.due_date
        Date.parse(due_date) < Date.yesterday
      end.map do |invoice|
        invoice.metadata.payer_view_url
      end
    end

  private

    def self.default_if_blank(value, default = "N/A")
      value.present? ? value : default
    end
  end
end
