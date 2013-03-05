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
  end
end
