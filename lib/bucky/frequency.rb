# Helper class for schedule_rule.frequency
class Bucky::Frequency
  attr_accessor :frequency

  def initialize(f)
    @frequency = f
  end

  [:weekly, :fortnightly, :monthly].each do |f|
    # define single?, weekly?, fortnightly? & monthly?
    define_method "#{f}?" do
      @frequency == f
    end
  end

  def one_off?
    @frequency.nil? || @frequency == :single || @frequency == :one_off
  end

  alias_method :single?, :one_off?

  def to_s
    @frequency.to_s
  end

  def recurs?
    !one_off?
  end
end
