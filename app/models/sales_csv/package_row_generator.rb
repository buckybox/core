class SalesCsv::PackageRowGenerator < SalesCsv::RowGenerator
private

  def order
    @order ||= data.order
  end

  def package
    @package ||= data
  end

  def delivery
    @delivery ||= data.delivery
  end

  def address
    @address ||= package.archived_address_details
  end

  def archived
    @archived ||= package
  end
end
