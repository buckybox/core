class SalesCsv::DeliveryRowGenerator < SalesCsv::RowGenerator
private

  def order
    @order ||= data.order
  end

  def package
    @package ||= data.package
  end

  def delivery
    @delivery ||= data
  end

  def address
    @address ||= package.archived_address_details
  end

  def archived
    @archived ||= package
  end
end
