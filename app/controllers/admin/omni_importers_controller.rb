class Admin::OmniImportersController < Admin::BaseController
  
  def index
    @omni_importers = OmniImporter.all
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
      @test_importer = Bucky::TransactionImports::OmniImport.new(@omni_importer.rows, YAML.load(@rules))
    rescue Psych::SyntaxError, StandardError => ex
      @error_message = "#{ex.to_s}\n#{ex.backtrace}"
    end
  end
end
