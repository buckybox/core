require 'spec_helper'

describe Distributor::Export::ExtrasController do
  sign_in_as_distributor

  let(:date){Date.current.to_s(:db)}

  before do
    @distributor.save!
    @post = lambda { post :index, export_extras: {date: date}}
  end

  it "downloads a csv" do
    allow(ExtrasCsv).to receive(:generate).and_return("")
    @post.call
    expect(response.headers['Content-Type']).to eq "text/csv; charset=utf-8; header=present"
  end

  it "exports customer data into csv" do
    allow(ExtrasCsv).to receive(:generate).and_return("I am the kind of csvs")
    @post.call
    expect(response.body).to eq "I am the kind of csvs"
  end

  it "calls ExtrasCsv.generate" do
    allow(ExtrasCsv).to receive(:generate)
    expect(ExtrasCsv).to receive(:generate).with(@distributor, Date.parse(date))
    @post.call
  end

end
