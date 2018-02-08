module Billing
  class XeroInvoice
    require 'xero_gateway'

    def self.gateway
      @gateway ||= XeroGateway::PrivateApp.new(
        Figaro.env.xero_oauth_consumer_key,
        Figaro.env.xero_oauth_consumer_secret,
        Rails.root.join("config/xero_private_key.pem"),
      )
    end

    def self.create!(invoice)
      distributor = invoice.distributor
      address = distributor.localised_address

      xero_invoice = gateway.build_invoice(
        invoice_type: "ACCREC",
        invoice_status: "AUTHORISED",
        date: Date.current,
        due_date: 1.month.from_now,
        line_amount_types: "Exclusive",
        currency_code: "NZD",
      )

      xero_invoice.contact.email = distributor.email
      xero_invoice.contact.name = distributor.name
      xero_invoice.contact.phone.number = distributor.phone
      xero_invoice.contact.address.line_1 = address.street
      xero_invoice.contact.address.city = address.city
      xero_invoice.contact.address.post_code = address.zip
      xero_invoice.contact.address.country = address.country

      line_item = XeroGateway::LineItem.new(
        description: invoice.description + " (from #{invoice.from} to #{invoice.to})",
        unit_amount: BigDecimal.new(invoice.amount.to_s),
        account_code: 202, # Bucky Box Distributor Fees - NZ
      )

      xero_invoice.line_items << line_item

      if xero_invoice.valid?
        # XXX: cannot send it yet https://xero.uservoice.com/forums/5528-xero-core-api/suggestions/1930769-be-able-to-email-approved-invoices-via-the-api
        xero_invoice.create
        Rails.logger.info "Invoice[#{xero_invoice.invoice_number}] created successfully"
      else
        Bugsnag.notify(RuntimeError.new(xero_invoice.errors.inspect))
      end

      xero_invoice.invoice_number
    end

    def self.overdue_invoices(email)
      contact = gateway.get_contacts(
        where: "EmailAddress=\"#{email}\""
      ).contacts.first

      return [] if contact.nil?

      invoices = gateway.get_invoices(
        contact_ids: [contact.contact_id],
        where: "Status=\"AUTHORISED\"",
      ).invoices

      invoices.select do |invoice|
        invoice.due_date < Date.yesterday
      end.map do |invoice|
        "https://go.xero.com/?InvoiceNumber=#{invoice.invoice_number}"
      end
    end
  end
end
