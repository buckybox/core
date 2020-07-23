module Billing
  class Transferwise
    @transactions = {}

    def self.overdue_invoices(distributor)
      currency = distributor.pricing.currency

      unless @transactions[currency]
        interval_end = Date.today
        interval_start = interval_end - 1.year
        url = "https://api.transferwise.com/v3/profiles/#{Figaro.env.transferwise_profile_id}/borderless-accounts/#{Figaro.env.transferwise_account_id}/statement.json?currency=#{currency}&intervalStart=#{interval_start}T00:00:00.000Z&intervalEnd=#{interval_end}T23:59:59.999Z"
        headers = { "Authorization" => "Bearer #{Figaro.env.transferwise_api_key}" }

        statement = Typhoeus.get(url, headers: headers, timeout: 5).request.response
        unless statement.success?
          Bugsnag.notify(RuntimeError.new("transferwise: unknown error (#{statement.code})"))
          return
        end

        json = JSON.parse(statement.body)
        transactions = json.fetch("transactions")
        @transactions[currency] = transactions
      end

      query_overdue_invoices(distributor).each do |invoice|
        paid = false
        invoice_amount = invoice.amount
        invoice_reference = invoice.number

        @transactions[currency].each do |transaction|
          transaction_amount = transaction.fetch("amount").fetch("value")
          transaction_reference = transaction.fetch("details").dig("paymentReference")

          Rails.logger.info "Reconciliating #{distributor.id}: #{transaction_amount} == #{invoice_amount} && #{transaction_reference} include? #{invoice_reference}"
          if transaction_amount == invoice_amount && transaction_reference.include?(invoice_reference)
            paid = true
            break
          end
        end

        invoice.update_attribute(:paid, true) if paid
      end

      query_overdue_invoices(distributor).map(&:reference)
    end

    def self.query_overdue_invoices(distributor)
      distributor.invoices.where("created_at >= ? AND created_at < ? AND paid = ?", Date.iso8601("2020-06-01"), 1.month.ago, false)
    end
  end
end
