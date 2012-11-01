class CompanyTeamImageUploader < BuckyImageUploader
  def default_url; end

  version :photo do
    process resize_to_fill: [600, 400]
  end

  version :half_size_photo, from_version: :photo do
    process resize_to_fit: [300, 200]
  end
end
