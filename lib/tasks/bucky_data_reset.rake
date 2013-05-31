# Obviously this code can be DANGEROUS
# Help clear out data distributors no longer need

namespace :bucky_data_reset do
  task make_damn_sure: :environment do
    make_damn_sure
  end

  desc 'Delete all the data you see for on delivery screen (and lots you do not see)'
  task clear_delivery_screen: :make_damn_sure do
    clear_delivery_screen(@distributor)
  end

  desc 'Delete all the data you see on the payment screen (and lots you do not see)'
  task clear_payment_screen: :make_damn_sure do
    clear_payment_screen(@distributor)
  end

  desc 'Reset the account balance to zero and remove all the order and transaction data (and lots you do not see)'
  task reset_customers: :make_damn_sure do
    clear_customer_data(@distributor)
  end

  desc 'Delete all the data you see on the customer screen (and lots you do not see)'
  task clear_customer_screen: :make_damn_sure do
    clear_customer_screen(@distributor)
  end

private

  def make_damn_sure
    @distributor = get_distributor
    double_check_distributor(@distributor)
  end

  def clear_delivery_screen(distributor)
    destroy_all_the_delivery_lists_and_their_deliveries(distributor)
    destroy_all_the_package_lists_and_their_packages(distributor)
  end

  def clear_payment_screen(distributor)
    destroy_all_import_transaction_lists(distributor)
    destroy_all_payments(distributor)
    destroy_all_deductions(distributor)
  end

  def clear_customer_screen(distributor)
    clear_customer_data(distributor)
    destroy_all_customers(distributor)
  end

  def clear_customer_data(distributor)
    destroy_all_orders(distributor)
    set_account_balance_to_zero(distributor) # do this before deleteing transactoins because it creates transactions
    destroy_all_transactions(distributor)
  end

  def destroy_all_customers(distributor)
    distributor.customers.each do |customer|
      sout "Deleting customer: #{customer.name}."
      customer.destroy
    end
  end

  def destroy_all_transactions(distributor)
    distributor.transactions.each do |transaction|
      sout "Deleting transaction #{transaction.description} for #{transaction.customer.name}."
      transaction.destroy
    end
  end

  def set_account_balance_to_zero(distributor)
    distributor.accounts.each do |account|
      sout "Reseting customer #{account.customer.name}'s account balance to zero."
      account.change_balance_to(0)
      account.save
    end
  end

  def destroy_all_orders(distributor)
    distributor.orders.each do |order|
      sout "Deleting #{order.customer.name}'s order for #{order.box}."
      order.destroy
    end
  end

  def destroy_all_deductions(distributor)
    distributor.deductions.each do |deduction|
      sout "Deleting deduction from: #{deduction.display_time}"
      deduction.destroy
    end
  end

  def destroy_all_payments(distributor)
    distributor.payments.each do |payment|
      sout "Deleting payment from: #{payment.display_time}"
      payment.destroy
    end
  end

  def destroy_all_import_transaction_lists(distributor)
    distributor.import_transaction_lists.each do |import_transaction_list|
      sout "Deleting import transaction list and import transactions from: #{import_transaction_list.created_at}"
      import_transaction_list.destroy
    end
  end

  def destroy_all_the_package_lists_and_their_packages(distributor)
    distributor.packing_lists.each do |packing_list|
      sout "Deleting packing list and packages from: #{packing_list.date}"
      packing_list.destroy
    end
  end

  def destroy_all_the_delivery_lists_and_their_deliveries(distributor)
    distributor.delivery_lists.each do |delivery_list|
      sout "Deleting delivery list and deliveries from: #{delivery_list.date}"
      delivery_list.destroy
    end
  end

  def double_check_distributor(distributor)
    sout "You are about to PERMANENTLY DELETE data from '#{distributor.name}'. Type in '#{distributor.parameter_name}' to confirm: "
    typed_distributor_name = sin.strip
    unless typed_distributor_name == distributor.parameter_name
      raise 'DANGER! DANGER! That was not the right Distributor name! ABORT! ABORT!'
    end
  end

  def get_distributor
    distributor = distributor_from_env
    distributor = distributor_from_input unless distributor
    distributor
  end

  def distributor_from_env
    id = ENV['distributor'].to_i
    Distributor.find_by_id(id)
  end

  def distributor_from_input
    sout 'What is the distributor ID you want to delete data from? '
    id = sin.strip.to_i
    Distributor.find_by_id(id)
  end

  def sout(value)
    STDOUT.puts(value)
  end

  def sin
    STDIN.gets
  end
end
