module Bucky
  # This are not used in the Bucky Box app but rather are convenience methods for development
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
  end
end
