# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BuckyBox::Application.initialize!

ActsAsTaggableOn.force_parameterize = true
ActsAsTaggableOn.remove_unused_tags = true

BuckyBox::Application.configure do
  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( admin.js admin.css distributor.js distributor.css customer.js customer.css print.js print.css sign_up_wizard.js sign_up_wizard.css )
end

$trace.enable

puts "======================================================== Boot time: #{Time.now - $boot_start}"

def get_wut
  $trace.disable do
  c = $wut_count
  t = Time.now - $wut_start
  $wut_count = 0
  $wut.select { |k,v| v > 1E4 }.sort_by {|k,v| v}.map do |k,v|
    file, lineno = k.split(":")

    line = if file == "(eval)"
      file
    else
      IO.readlines(file)[lineno.to_i].strip
    end

    "<code>#{line}</code> # executed <b>#{v}</b> times from <em>#{k}</em>"
  end << c << t
  end
end

puts get_wut.join("\n")


binding.pry
