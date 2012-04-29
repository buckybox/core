module Bucky
  autoload :Schedule, 'bucky/schedule'
  autoload :Import, 'bucky/import'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def schedule_for(name)
      define_method name do
        Bucky::Schedule.from_hash(self[name]) if self[name]
      end

      define_method "#{name}=" do |s|
        if s.is_a?(Hash)
          raise "Please don't pass in a Hash"
        elsif s.nil?
          self[name] = {}
        elsif s.is_a?(Bucky::Schedule) || s.class.name == 'RSpec::Mocks::Mock'
          self[name] = s.to_hash
        else
          raise "Expecting a Bucky::Schedule but got a #{s.class}"
        end
      end

      self.serialize name, Hash
    end
  end

  def create_schedule_for(name, start_time, frequency, days_by_number = nil)
    schedule = Bucky::Schedule.build(start_time, frequency, days_by_number)
    self.send("#{name}=", schedule)

    return schedule
  end
end

