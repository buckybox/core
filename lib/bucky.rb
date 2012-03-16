module Bucky
  autoload :Schedule, 'bucky/schedule'

  DAYS = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def schedule_for(name)
      Bucky::Util.record_schedule(self.name, name)

      self.serialize name, Hash

      define_method name do
        bs = nil
        if self[name]
          bs = Bucky::Schedule.from_hash(self[name])
          bs.time_zone = local_time_zone
        end
        bs
      end

      define_method "#{name}=" do |s|
        if s.is_a?(Hash)
          throw("Please don't pass in a Hash")
        elsif s.nil?
          self[name] = {}
        elsif s.is_a?(Bucky::Schedule)
          self[name] = s.to_hash
        else
          throw("Expecting a Bucky::Schedule but got a #{s.class}")
        end
      end
    end
  end

  def create_schedule_for(name, start_time, frequency, days_by_number = nil)
    schedule = Bucky::Schedule.new(start_time.utc)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time.utc)
    elsif frequency == 'monthly'
      monthly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

      recurrence_rule = IceCube::Rule.monthly.day_of_week(monthly_days_hash)
      schedule.add_recurrence_rule(recurrence_rule)
    else
      if frequency == 'weekly'
        weeks_between_deliveries = 1
      elsif frequency == 'fortnightly'
        weeks_between_deliveries = 2
      end

      recurrence_rule = IceCube::Rule.weekly(weeks_between_deliveries).day(*days_by_number)
      schedule.add_recurrence_rule(recurrence_rule)
    end

    self.send("#{name}=", schedule)
    schedule
  end

  module Util
    def self.record_schedule(klass, column)
      @recorded_schedules ||= {}
      @recorded_schedules[klass] ||= []
      @recorded_schedules[klass] << column
    end

    def self.schedules
      # Load all models so they can initialize and set up schedules
      (ActiveRecord::Base.connection.tables - %w[schema_migrations]).each do |table|
        table.classify.constantize rescue nil
      end
      @recorded_schedules.clone
    end

    def self.update_schedules_time_zone(time_zone = BuckyBox::Application.config.time_zone)
      Time.use_zone(time_zone) do
        schedules.each do |klass, schedule_names|
          klass.constantize.all.each do |klass_instance|
            schedule_names.each do |schedule_name|
              schedule = klass_instance.send schedule_name
              schedule.start_time = schedule.start_time.utc
              klass_instance.send("#{schedule_name}=", schedule)
              klass_instance.save!
            end
          end
        end
      end
    end

    def self.args_to_utc(*args)
      utc_args = args.collect do |arg|
        if arg.respond_to?(:utc)
          arg.utc
        elsif arg.respond_to?(:to_time)
          arg.to_time.utc
        else
          arg
        end
      end
    end
  end
end

