# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BuckyBox::Application.initialize!

ActsAsTaggableOn.force_parameterize = true
ActsAsTaggableOn.remove_unused_tags = true

