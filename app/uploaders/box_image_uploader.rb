class BoxImageUploader < BuckyImageUploader
  version :webstore_thumb do
    process resize_to_fit: [270, 540]
  end
end
