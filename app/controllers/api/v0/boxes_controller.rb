class Api::V0::BoxesController < Api::V0::BaseController
	
	api :GET, '/boxes', "Returns list of boxes"
	param :embed, String, desc: "Children available: available_extras, images"
	example '/boxes?embed=available_extras+images

Returns something like:

[
    {
        "box": {
            "id": 1,
            "name": "My first box",
            "description": "One box of delicious",
            "likes": false,
            "dislikes": false,
            "price_cents": 0,
            "available_single": false,
            "available_weekly": false,
            "available_monthly": false,
            "extras_limit": -1,
            "exclusions_limit": 0,
            "substitutions_limit": 0,
            "hidden": false,
            "box_image": {
                "box_image": {
                    "url": "/assets/fallbacks/box/box_image/default.png",
                    "thumb": {
                        "url": "/assets/fallbacks/box/box_image/thumb_default.png"
                    },
                    "small_thumb": {
                        "url": "/assets/fallbacks/box/box_image/small_thumb_default.png"
                    },
                    "tiny_thumb": {
                        "url": "/assets/fallbacks/box/box_image/tiny_thumb_default.png"
                    },
                    "webstore": {
                        "url": "/assets/fallbacks/box/box_image/webstore_default.png"
                    }
                }
            },
            "extras": [
                {
                    "extra": {
                        "id": 1,
                        "name": "My first extra ",
                        "unit": "1",
                        "price_cents": 700,
                        "hidden": false
                    }
                },
                {
                    "extra": {
                        "id": 2,
                        "name": "My second extra",
                        "unit": "1",
                        "price_cents": 700,
                        "hidden": false
                    }
                }
            ]
        }
    }
]'
	def index 
		@boxes = @distributor.boxes.all
        @box_images = @boxes.each_with_object({}) do |box, hash|
          hash[box.id] = box.box_image.versions.each_with_object({}) do |(version, image), images|
              images[version] = "//"+request.host_with_port+image.url
          end
        end
    end
end