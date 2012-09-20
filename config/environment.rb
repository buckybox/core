# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BuckyBox::Application.initialize!

ActsAsTaggableOn.force_parameterize = true
ActsAsTaggableOn.remove_unused_tags = true

require 'hodel_3000_compliant_logger'
config.logger = Hodel3000CompliantLogger.new(config.log_path)
