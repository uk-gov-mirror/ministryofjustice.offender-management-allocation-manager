Turnout.configure do |config|
  config.app_root = '.'
  config.named_maintenance_file_paths = { default: config.app_root.join('tmp', 'maintenance.yml').to_s }
  config.maintenance_pages_path = config.app_root.join('public').to_s
  config.default_maintenance_page = Turnout::MaintenancePage::HTML
  config.default_reason = 'We are carrying out essential maintenance. Try again soon.'
  config.default_allowed_paths = ['/assets']
  config.default_response_code = 503
  config.default_retry_after = 7200
end
