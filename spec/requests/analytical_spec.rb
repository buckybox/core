require 'spec_helper'

describe 'analytical' do

  context "when logged out" do
    it "tracks view sign in form" do
      visit new_distributor_session_path
      page.should have_content('view_sign_in')
    end
  end

end
