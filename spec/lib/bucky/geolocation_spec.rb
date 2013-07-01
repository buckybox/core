require 'spec_helper'

describe Bucky::Geolocation do
  describe ".get_country" do
    {
      "202.162.73.2" => "New Zealand", # TradeMe IP
      "67.205.28.58" => "United States", # one of our box
      "127.0.0.1" => "Reserved",
    }.each do |ip, country|
      it "returns the right country" do
        Bucky::Geolocation.get_country(ip).should eq country
      end
    end
  end

  describe ".get_time_zone" do
    before do
      Fabricate(:country)
    end

    it "returns the right time zone" do
      Bucky::Geolocation.get_time_zone("New Zealand").should eq "Auckland"
    end
  end

  describe ".get_geoip_info" do
    it "doesn't take more than a second" do
      Benchmark.realtime do
        Bucky::Geolocation.get_geoip_info "202.162.73.2"
      end.should be < 1
    end

    it "returns nil when it times out" do
      Net::HTTP::Get.stub(:new) { sleep 2 }
      Bucky::Geolocation.get_geoip_info("202.162.73.2").should be_nil
    end
  end
end

