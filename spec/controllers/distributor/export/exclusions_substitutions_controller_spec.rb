require 'spec_helper'

describe Distributor::Export::ExclusionsSubstitutionsController do
  sign_in_as_distributor

  let(:date) { Date.current.to_s(:db) }

  before do
    @distributor.save!
  end

  it "downloads a csv" do
    allow(ExclusionsSubstitutionsCsv).to receive(:generate).and_return("")
    post :index, date: date, deliveries: true
    expect(response.headers['Content-Type']).to eq "text/csv; charset=utf-8; header=present"
  end

  it "exports customer data into csv" do
    allow(ExclusionsSubstitutionsCsv).to receive(:generate).and_return("I am the kind of csvs")
    post :index, date: date, deliveries: true
    expect(response.body).to eq "I am the kind of csvs"
  end

  it "calls ExclusionsSubstitutionsCsv.generate" do
    allow(ExclusionsSubstitutionsCsv).to receive(:generate)
    expect(ExclusionsSubstitutionsCsv).to receive(:generate).with(Date.parse(date), [])
    post :index, date: date, deliveries: true
  end

end
