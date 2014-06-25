require "spec_helper"
require "i18n-spec"

shared_examples_for "a good locale file" do |locale_file|
  describe locale_file do
    it { should be_parseable }
    it { should have_valid_pluralization_keys }
    it { should_not have_missing_pluralization_keys }
    it { should have_one_top_level_namespace }
    # it { should be_named_like_top_level_namespace } # NOTE: we use another namespacing
    it { should_not have_legacy_interpolations }
    it { should have_a_valid_locale }
  end
end

application_locale_files = Rails.configuration.i18n[:load_path] - Rails.configuration.i18n[:railties_load_path]

Dir.glob(application_locale_files) do |locale_file|
  describe locale_file do
    it_behaves_like 'a good locale file', locale_file
  end
end
