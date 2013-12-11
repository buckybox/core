# An email template which can be personalised for a given customer
class EmailTemplate

  # white-list of special keywords to be replaced
  KEYWORDS = {
    first_name:            :first_name,
    last_name:             :last_name,
    account_balance:       :account_balance_with_currency,
    address:               :address,
    next_delivery_summary: :next_delivery_summary,
  }

  # 2-array with left and right keyword delimiters
  DELIMITERS = %w({ })

  ATTRIBUTES = [:subject, :body]

  attr_reader(*ATTRIBUTES)
  attr_reader :errors

  def initialize(subject, body)
    @subject, @body = subject, body

    @errors = []
  end

  def valid?
    ATTRIBUTES.each do |attribute|
      if public_send(attribute).blank?
        @errors << "#{attribute.to_s.capitalize} can't be blank"
      end
    end

    unless unknown_keywords.empty?
      @errors << "Unknown keywords found: #{unknown_keywords.join(', ')}"
    end

    @errors.empty?
  end

  def personalise customer
    raise @errors unless valid?

    customer = customer.decorate unless customer.decorated?

    replace_map = KEYWORDS.inject({}) do |hash, (keyword,method)|
      replace = customer.public_send(method)
      hash.merge!(keyword => replace.to_s)
    end.freeze

    personalised = {}

    ATTRIBUTES.each do |attribute|
      attribute_value = public_send(attribute).dup

      replace_map.each do |key, value|
        attribute_value.gsub!(EmailTemplate.keyword_with_delimiters(key), value)
      end

      personalised[attribute] = attribute_value
    end

    EmailTemplate.new(personalised[:subject], personalised[:body]).freeze
  end

  def unknown_keywords
    regexp = /#{Regexp.escape(DELIMITERS.first)}(.*?)#{Regexp.escape(DELIMITERS.last)}/

    present_keywords = ATTRIBUTES.map do |attribute|
      public_send(attribute).to_s.scan(regexp).map(&:first)
    end.flatten

    present_keywords - self.class.keywords
  end

  def self.keyword_with_delimiters keyword
    "#{DELIMITERS.first}#{keyword}#{DELIMITERS.last}"
  end

  def self.keywords_with_delimiters
    keywords.map do |keyword|
      keyword_with_delimiters keyword
    end
  end

private

  def self.keywords
    KEYWORDS.keys.map(&:to_s)
  end

  def self.methods
    KEYWORDS.values
  end
end
