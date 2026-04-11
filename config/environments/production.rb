require "active_support/core_ext/integer/time"

Rails.application.configure do

  # Servir arquivos estáticos (necessário no Render)
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Assets
  config.assets.compile = true

  # Código não recarrega
  config.enable_reloading = false
  config.eager_load = true

  # Erros
  config.consider_all_requests_local = false

  # Cache
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  # Active Storage (local simples)
  config.active_storage.service = :local

  # Logs
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Health check
  config.silence_healthcheck_path = "/up"

  # Depreciações
  config.active_support.report_deprecations = false

  # Active Job (fila simples)
  config.active_job.queue_adapter = :async

  # Action Cable (resolve erro do cable)
  config.action_cable.adapter = :async

  # Mailer
  config.action_mailer.default_url_options = { host: "example.com" }

  # I18n
  config.i18n.fallbacks = true

  # Active Record
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # SECRET KEY
  config.secret_key_base = ENV["SECRET_KEY_BASE"]

end