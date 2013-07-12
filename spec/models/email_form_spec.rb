require 'spec_helper'

describe EmailForm do
  let(:fields){{
    subject: 'Car door is broken',
    body: 'A very excited cat tried to run through the door... Sorry.',
    preview_email: 'admin@buckybox.com'
  }}
  let(:distributor){ double('Distributor', email: 'test@test.com', email_to: 'Test Dummy <test@test.com>', contact_name: 'Test Dummy') }

  it 'fucking well better send email' do
    email_form = EmailForm.new(fields)
    Distributor.stub(:keep_updated).and_return([distributor])

    mock_delay = double('mock_delay').as_null_object
    DistributorMailer.stub(:delay).and_return(mock_delay)
    mock_delay.should_receive(:update_email).with(email_form, distributor)

    email_form.send!
  end

  it 'fucking well better send email' do
    email_form = EmailForm.new(fields)
    DistributorMailer.update_email(email_form, distributor).deliver

    email = ActionMailer::Base.deliveries.last
    email.to.should eq([distributor.email])
    email[:from].to_s.should eq(Figaro.env.support_email)
    email[:reply_to].to_s.should eq(Figaro.env.support_email)
    email.body.parts.find{|p| p.content_type.match(/plain/)}.body.should match(fields[:body])
    email.subject.should match(fields[:subject])
  end
end
