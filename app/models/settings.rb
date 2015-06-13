class Settings < Settingslogic
  source "#{Rails.root}/config/settings.yml"
  namespace Rails.env
  suppress_errors true
end
