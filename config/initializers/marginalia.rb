require "marginalia"

Marginalia.application_name = "core"
Marginalia::Comment.components = [:application, :controller_with_namespace, :action, :line]
