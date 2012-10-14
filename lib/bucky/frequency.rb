# Helper class for schedule.frequency
class Bucky::Frequency
  attr_accessor :frequency

  def initialize(f)
    @frequency = f
  end

  [:weekly, :fortnightly, :monthly].each do |f|
    # define single?, weekly?, fortnightly? & monthly?
    define_method "#{f.to_s}?" do
      @frequency == f
    end
  end

  def one_off?
    @frequency == :single || @frequency == :one_off
  end

  alias :single? :one_off?

  def to_s
    @frequency.to_s
  end

  def reoccurs?
    @frequency != :single
  end
end
