$boot_start = Time.now

module VerboseRequire
  def included(base)
    puts "INCLUDED IN #{base.ancestors}"
    base.class_eval do
      $require_count ||= 0
      require 'benchmark'
      alias :old_require :require
      def require(file)
        duration = Benchmark.realtime { old_require(file) }
        $require_count += 1
        if duration > 0.1 || true
          ms = (1000 * duration.round(3)).to_i
          puts "VerboseRequire (included) ##{$require_count}: #{file} (#{ms}ms)"
        end
      end
    end
  end

  def self.included(base)
    puts "SELF.INCLUDED IN #{base.ancestors}"
    base.class_eval do
      $require_count ||= 0
      require 'benchmark'
      alias :old_require :require
      def require(file)
        new = false
        duration = Benchmark.realtime { new = old_require(file) }

        if new
          $require_count += 1

          unless file.include?("/")
          # if duration > 0.1 || true
            ms = (1000 * duration.round(3)).to_i
            # puts "VerboseRequire (self.included in #{self.class}) ##{$require_count}: #{file} (#{ms}ms)"
            puts "VerboseRequire ##{$require_count}: #{file} (#{ms}ms)"
            system "echo #{ms},#{file} >> load.csv"
          end
        end

        new
      end
    end
  end
end

Kernel.module_eval do |m|
  class << self
    include VerboseRequire
  end
end

include VerboseRequire

$wut = Hash.new(0)
$wut_count = 0
$wut_time = nil
require 'fnordmetric'
api = FnordMetric::API.new

$trace = TracePoint.new(:line) do |tp|
  # p "TP: #{tp.path}:#{tp.lineno} (#{tp.event} method #{tp.method_id})"
  key = "#{tp.path}:#{tp.lineno}"
  # return if key.include?("journey") # inf loop
  $wut[key] += 1
  $wut_start = Time.now if $wut_count.zero?
  $wut_count += 1
  # puts "EVENT #{key}"
  # api.event(:_type => :search, :keyword => key)
end

# trace.enable



require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
