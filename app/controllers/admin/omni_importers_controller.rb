class Admin::OmniImportersController < Admin::BaseController
  
  def index
    @omni_importers = OmniImporter.joins("LEFT JOIN countries ON countries.id = omni_importers.country_id").order('countries.name, omni_importers.name').all
    # Put those with blank countries on top
    globals = []
    @omni_importers = @omni_importers.reject do |oi|
      if oi.country.blank?
        globals << oi
        true
      else
        false
      end
    end
    @omni_importers = globals + @omni_importers
  end

  def new
    @omni_importer = OmniImporter.new
  end

  def create
    @omni_importer = OmniImporter.new(params[:omni_importer])

    if @omni_importer.save
      redirect_to edit_admin_omni_importer_path(@omni_importer), notice: 'Omni Importer saved.'
    else
      render :new
    end
  end

  def edit
    @omni_importer = OmniImporter.find(params[:id])
    get_test_importer(@omni_importer.rules) unless @omni_importer.rules.blank?
  end

  def update
    @omni_importer = OmniImporter.find(params[:id])

    if @omni_importer.update_attributes(params[:omni_importer])
      redirect_to edit_admin_omni_importer_path(@omni_importer), notice: 'Omni Importer saved.'
    else
      render :edit
    end
  end

  def test
    @omni_importer = OmniImporter.find(params[:id])
    get_test_importer(params[:rules])
    render partial: 'admin/omni_importers/test'
  end

  def get_test_importer(rules)
    @rules = rules
    begin
      @test_importer = Bucky::TransactionImports::OmniImport.new(@omni_importer.test_rows, YAML.load(@rules))
    rescue StandardError => ex
      @error_message = "#{ex.to_s}\n#{ex.backtrace}"
    rescue Psych::SyntaxError => ex
      @error_message = "YAML syntax is wrong
#{ex.message}"
    end
  end
end
