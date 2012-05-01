# Helper class for schedule.frequency
class Bucky::Frequency
  attr_accessor :frequency

  def initialize(f)
    @frequency = f
  end

  [:single, :weekly, :fortnightly, :monthly].each do |f|
    # define single?, weekly?, fortnightly? & monthly?
    define_method "#{f.to_s}?" do
      @frequency == f
    end
  end

  def to_s
    @frequency.to_s
  end
end
