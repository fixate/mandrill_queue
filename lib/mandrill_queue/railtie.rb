require "rails"
require "abstract_controller/railties/routes_helpers"

module MandrillQueue
  class Railtie < Rails::Railtie # :nodoc:
    config.eager_load_namespaces << MandrillQueue

    initializer "mandrill_queue.initialize" do |app|
      ActiveSupport.on_load(:mandrill_queue) do
        include AbstractController::UrlFor
        extend ::AbstractController::Railties::RoutesHelpers.with(app.routes)
        include app.routes.mounted_helpers
      end
    end
  end
end
