require 'fast_spec_helper'
require_model 'email_form'
required_constants %w(DistributorMailer Distributor)

describe EmailForm do
  let(:fields){{
    subject: 'Car door is broken',
    body: 'A very excited cat tried to run through the door... Sorry.',
    preview_email: 'admin@buckybox.com'
  }}

  it 'fucking well better send email' do
    Distributor.stub(:keep_updated).and_return([])
    EmailForm.new(fields).send!
    ActionMailer::Base.deliveries.last
  end
end
