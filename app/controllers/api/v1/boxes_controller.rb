class Api::V1::BoxesController < Api::V1::BaseController
  api :GET, '/boxes', "Returns list of boxes"
  param :embed, String, desc: "Children available: extras, images, box_items"
  example '/v1/boxes?embed=extras,images,box_items'
  def index
    @boxes = @distributor.boxes.not_hidden.all

    fetch_images if with_images?
  end

  api :GET, '/boxes/:id', "Returns single box"
  param :id, Integer, desc: "ID of the box to select"
  param :embed, String, desc: "Children available: extras, images, box_items"
  example '/v1/boxes/123?embed=extras,images,box_items'
  def show
    @box = @distributor.boxes.not_hidden.find_by(id: params[:id])
    return not_found if @box.nil?

    fetch_images if with_images?
  end

private

  def fetch_images
    boxes = @boxes || [@box]
    @images = boxes.each_with_object({}) do |box, hash|
      hash[box.id] = box.box_image.versions.each_with_object({}) do |(version, image), images|
        images[version] = ["//", Figaro.env.host, view_context.image_path(image.url)].join
      end
    end
  end

  def with_images?
    @embed.include? "images"
  end
end
