source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

gem "sqlite3", ">= 2.1", group: [:development, :test]
gem "pg", group: :production

# Use Active Model has_secure_password
# gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data", platforms: %i[ windows jruby ]

# gem "solid_cache"

gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "devise", "~> 5.0"
gem "roo", "~> 3.0"
gem "simple_calendar", "~> 3.1"