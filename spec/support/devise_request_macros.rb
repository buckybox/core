module DeviseRequestMacros
  def distributor_login
    before(:each) do
      @distributor = Fabricate(:distributor)
      visit new_distributor_session_path
      fill_in 'Email', :with => @distributor.email
      fill_in 'Password', :with => @distributor.password
      click_button 'Sign In'
    end
  end
end

