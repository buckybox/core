require "fnordmetric"

FnordMetric.namespace :myapp do

  gauge :events_per_second, :tick => 1.second

  toplist_gauge :popular_keywords,
    :title => "Popular Keywords",
    :resolution => 3.seconds,
    :autoupdate => 1


  event :search do
    observe :popular_keywords, data[:keyword]
  end

  event :"*" do
    incr :events_per_second
  end

end

FnordMetric.options = {
  :event_queue_ttl  => 10, # all data that isn't processed within 10s is discarded to prevent memory overruns
  :event_data_ttl   => 3600, # event data is stored for one hour (needed for the active users view)
  :session_data_ttl => 3600, # session data is stored for one hour (needed for the active users view)
  :redis_prefix => "fnordmetric"
}

def start_example_data_generator

  api = FnordMetric::API.new
  Thread.new do
    loop do
      api.event(:_type => :search, :keyword => (%w(Donau Dampf Schiff Fahrts Kaptitaens Muetzen Staender).shuffle[0..2] * ""))
      sleep (rand(10)/10.to_f)
    end
  end

end

# start_example_data_generator

FnordMetric::Web.new(:port => 4242)
FnordMetric::Acceptor.new(:protocol => :tcp, :port => 2323)
FnordMetric::Worker.new
FnordMetric.run

