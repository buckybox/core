class CompanyLogoUploader < BuckyImageUploader
  def default_url; end

  version :banner do
    process resize_to_fit: [980, 160]
  end

  version :half_size_banner, from_version: :banner do
    process resize_to_fit: [490, 80]
  end
end
