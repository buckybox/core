require 'spec_helper'

describe EmailForm do
  let(:fields){{
    subject: 'Car door is broken',
    body: 'A very excited cat tried to run through the door... Sorry.',
    preview_email: 'admin@buckybox.com'
  }}
  let(:distributor){
    d = double('Distributor')
    d.stub(:email).and_return('test@test.com')
    d.stub(:contact_name).and_return('Test Dummy')
    d
  }

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
    email.body.should match(fields[:body])
    email.subject.should match(fields[:subject])
  end
end
