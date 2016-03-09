gem "font-awesome-sass"

gem_group :development, :test do
  gem "dotenv-rails"
  gem "factory_girl_rails"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
end

gem_group :development do
  gem "administrate"
  gem "awesome_print"
  gem "letter_opener"
  gem "quiet-assets"
  gem "rails-erd"
end

gem_group :test do
  gem "capybara-webkit"
  gem "database_cleaner"
  gem "percy"
  gem "shoulda-matchers"
  gem "webmock"
end

environment "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }",
            env: "development"

rakefile("setup.rake") do
  <<-TASK
    task :setup do
      puts "Making sure you have all the gems this app depends upon installed..."
      `bundle install`

      puts "Building the database..."
      `rake db:migrate`

      puts "Populating the database with dummy data.."
      `rake db:seed`
    end
  TASK
end

run "mv README.rdoc README.md"

File.open("README.md", "w") do |f|
  f.puts "# #{@app_name}"
  f.puts
  f.puts "## Setup"
  f.puts
  f.puts " 1. **Fork** the original repository to your own GitHub account."
  f.puts " 1. Clone **your fork** down to your computer (not the original)."
  f.puts " 1. Open the entire folder you downloaded in Atom."
  f.puts " 1. Navigate to the folder in Terminal."
  f.puts " 1. `rake setup`"
  f.puts " 1. `rails server`"
end

File.open("app.json.erb", "w") do |f|
  f.puts "{"
  f.puts "  \"name\":\"<%= @app_name.dasherize %>\","
  f.puts "  \"scripts\": {},"
  f.puts "  \"env\": {"
  f.puts "    \"APPLICATION_HOST\": {"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"EMAIL_RECIPIENTS\": {"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"HEROKU_APP_NAME\": {"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"HEROKU_PARENT_APP_NAME\": {"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"RACK_ENV\":{"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"SECRET_KEY_BASE\":{"
  f.puts "      \"generator\": "secret""
  f.puts "    },"
  f.puts "    \"SMTP_ADDRESS\":{"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"SMTP_DOMAIN\":{"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"SMTP_PASSWORD\":{"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"SMTP_USERNAME\":{"
  f.puts "      \"required\": true"
  f.puts "    },"
  f.puts "    \"WEB_CONCURRENCY\":{"
  f.puts "      \"required\":true"
  f.puts "    }"
  f.puts "  },"
  f.puts "  \"addons\": ["
  f.puts "    \"heroku-postgresql\""
  f.puts "  ]"
  f.puts "}"
end

after_bundle do
  git :init
  git add: "."
  git commit: "-a -m \"rails new\""
end
