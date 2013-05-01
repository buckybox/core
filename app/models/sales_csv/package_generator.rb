class SalesCsv::PackageGenerator < SalesCsv::Generator
  def initialize(data, options = {})
    @row_generator = options.fetch(:row_generator, PackageRowGenerator)
    super(data)
  end
end
