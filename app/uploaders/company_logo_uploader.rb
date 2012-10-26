class CompanyLogoUploader < BuckyImageUploader
  def default_url; end

  version :banner do
    process resize_to_fit: [980, 160]
  end

  version :frame_banner, from_version: :banner do
    process resize_to_fit: [570, 128]
  end
end
