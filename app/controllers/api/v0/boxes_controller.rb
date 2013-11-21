class Api::V0::BoxesController < Api::V0::BaseController
  api :GET, '/boxes', "Returns list of boxes"
  param :embed, String, desc: "Children available: extras, images"
  example '/v0/boxes?embed=extras,images,box_items'
  def index
    @boxes = @distributor.boxes.all
    @items = @distributor.line_items
    @box_images = @boxes.each_with_object({}) do |box, hash|
      hash[box.id] = box.box_image.versions.each_with_object({}) do |(version, image), images|
        images[version] = "//"+request.host_with_port+image.url
      end
    end
  end

  api :GET, '/boxes/:id', "Returns single box"
  param :id, Integer, desc: "ID of the box to select"
  param :embed, String, desc: "Children available: extras, images, box_items"
  example '/v0/boxes/123?embed=extras,images,box_items'
  def show
    box_id = params[:id]
    return not_found if box_id.nil?
    @box = @distributor.boxes.find_by(id: box_id)
    return not_found if @box.nil?
    @items = @distributor.line_items
    @box_images = @box.box_image.versions.each_with_object({}) do |(version, image), images|
      images[version] = "//"+request.host_with_port+image.url
    end
  end
end
