# An email template which can be personalised for a given customer
class EmailTemplate

  # white-list of special keywords to be replaced
  KEYWORDS = %w(first_name last_name account_balance)

  attr_accessor :subject, :body
  attr_reader :errors

  def initialize(subject = nil, body = nil)
    @subject, @body = subject, body
    @errors = []
  end

  def valid?
    @errors << "Subject can't be blank" if subject.blank?
    @errors << "Body can't be blank" if body.blank?

    unless unknown_keywords.empty?
      @errors << "Unknown keywords found: #{unknown_keywords.join(', ')}"
    end

    @errors.empty?
  end

  def personalise customer
    raise @errors unless valid?

    personalised_body = body.dup

    KEYWORDS.each do |keyword|
      replace = customer.public_send(keyword)

      # NOTE: format money - will need to be less ad-hoc if we add new keywords
      replace = replace.format if replace.respond_to? :format

      personalised_body.gsub! "[#{keyword}]", replace.to_s
    end

    OpenStruct.new({
      subject: subject,
      body: personalised_body
    }).freeze
  end

  def unknown_keywords
    keywords = body.to_s.scan(/\[(.*?)\]/).map(&:first)
    keywords - KEYWORDS
  end
end
