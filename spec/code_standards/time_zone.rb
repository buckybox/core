require 'spec_helper'

describe "All Application Code" do
  context 'with respect to time zone functionality' do

    it 'should see all developers are using Time.current or Date.current' do
      bad_uses = ["Time.new", "Time.now", "Date.today", "Date.new"]
      bad_uses.each do |bad_use|
        `git grep --no-index #{bad_use}`.should eq "spec/code_standards/time_zone.rb:      bad_uses = #{bad_uses.inspect}\n"
      end
    end
  end
end
