def source_paths
  Array(super) +
    [File.join(File.expand_path(File.dirname(__FILE__)), "files")]
end

# Clean up entire Gemfile, remove web console and byebug
# Add default favicon
# Include gem "administrate-field-image"

# Puma
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# heroku create fd-html-intro
# heroku pipelines:create -a fd-html-intro --stage=production

# Create branch for -target
# Create deploy script to push target branch to heroku
# git push heroku target:master

# gemfile_lines = File.readlines("Gemfile")
# gemfile_lines.insert(0, "ruby \"2.2.4\"", "")
# File.open("Gemfile", "w") do |f|
#   f.puts gemfile_lines
# end

gem "font-awesome-sass", '~> 4.5.0'
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

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
  gem "better_errors"
  gem "binding_of_caller"
  gem "letter_opener"
  gem "quiet_assets"
  gem "sqlite3"
end

gem_group :production do
  gem "pg"
  gem "rails_12factor"
end

gem_group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "percy-capybara"
  gem "shoulda-matchers"
  gem "webmock"
end

gemfile_lines = File.readlines("Gemfile")

gemfile_lines[gemfile_lines.index("source 'https://rubygems.org'\n")] = "source 'http://rubygems.org'\n"

gemfile_lines.delete("# Use sqlite3 as the database for Active Record\n")
gemfile_lines.delete("gem 'sqlite3'\n")

File.open("Gemfile", "w") do |file|
  file.puts gemfile_lines
end

run "bundle install --without production"

after_bundle do
  environment "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }",
              env: "development"

  # Modify the existing bin/setup instead
  # file("setup.sh") do
  #   <<-SCRIPT.gsub(/^\s+/, "")
  #     #!/bin/bash
  #
  #     echo "Making sure you have all the gems this app depends upon installed..."
  #     bundle install --without production
  #
  #     echo "Building the database..."
  #     rake db:migrate
  #
  #     echo "Populating the database with dummy data.."
  #     rake db:seed
  #   SCRIPT
  # end
  #
  # file("setup.bat") do
  #   <<-SCRIPT.gsub(/^\s+/, "")
  #     echo "Making sure you have all the gems this app depends upon installed..."
  #     bundle install --without production
  #
  #     echo "Building the database..."
  #     rake db:migrate
  #
  #     echo "Populating the database with dummy data.."
  #     rake db:seed
  #   SCRIPT
  # end

  run "rm README.rdoc"
  file "README.md", <<-MD.gsub(/^    /, "")
    # #{@app_name.titleize}

    ## Setup

    1. Clone this repository down to your computer.
    1. In the GitHub app, create a new branch for your work.
    1. Open the entire folder you downloaded in Atom.
    1. Make your first change.
    1. Commit and Publish and verify that your branch shows up here on this page in the "Branch" dropdown box.
    1. Open a Pull Request when you are ready to see how you are doing.
    1. You can continue to Sync new commits right up until the due date.
  MD

  run "rm app/assets/stylesheets/application.css"
  file "app/assets/stylesheets/application.scss", <<-SCSS.gsub(/^    /, "")
    @charset "utf-8";
    @import "font-awesome-sprockets";
    @import "font-awesome";
  SCSS

  generate "rspec:install"

  run "rm .rspec"
  file ".rspec", <<-TEXT.gsub(/^    /, "")
    --color
    --format documentation
    --order default
    --require spec_helper
  TEXT

  rails_helper_lines = File.readlines("spec/rails_helper.rb")
  requires = [
    "require \"capybara/rails\"",
    "require \"capybara/rspec\""
  ]
  rails_helper_lines.insert(7, requires)
  rails_helper_lines.insert(-2, "  WebMock.disable_net_connect!(allow: \"percy.io\")")
  File.open("spec/rails_helper.rb", "w") do |f|
    f.puts rails_helper_lines
  end

  file "spec/support/shoulda_matchers.rb", <<-RB.gsub(/^    /, "")
    RSpec.configure do |config|
      Shoulda::Matchers.configure do |config|
        config.integrate do |with|
          with.test_framework :rspec
          with.library :rails
        end
      end
    end
  RB

  file "spec/support/database_cleaner.rb", <<-RB.gsub(/^    /, "")
    RSpec.configure do |config|
      config.before(:suite) do
        DatabaseCleaner.clean_with(:deletion)
      end

      config.before(:each) do
        DatabaseCleaner.strategy = :transaction
      end

      config.before(:each, js: true) do
        DatabaseCleaner.strategy = :deletion
      end

      config.before(:each) do
        DatabaseCleaner.start
      end

      config.after(:each) do
        DatabaseCleaner.clean
      end
    end
  RB

  file "spec/support/factory_girl.rb", <<-RB.gsub(/^    /, "")
    RSpec.configure do |config|
      config.include FactoryGirl::Syntax::Methods
    end
  RB

  spec_helper_lines = File.readlines("spec/spec_helper.rb")
  backtrace_lines = <<-RB.gsub(/^  /, "").split("\n")
    RSpec.configure do |config|
      config.backtrace_exclusion_patterns = [
        /\/lib\d*\/ruby\//,
        /bin\//,
        /gems/,
        /spec\/spec_helper\.rb/,
        /lib\/rspec\/(core|expectations|matchers|mocks)/
      ]
    end
  RB
  spec_helper_lines.insert(-2, backtrace_lines)

  spec_helper_lines = File.readlines("spec/spec_helper.rb")
  percy_lines = <<-RB.gsub(/^  /, "").split("\n")
    RSpec.configure do |config|
      config.before(:suite) do
        Percy.config.access_token = ENV["PERCY_TOKEN"]
        # Percy.config.default_widths = [320, 768, 1280] # to test responsiveness
      end

      config.before(:suite) { Percy::Capybara.initialize_build }
      config.after(:suite) { Percy::Capybara.finalize_build }
    end
  RB
  spec_helper_lines.insert(-2, percy_lines)

  json_formatter_lines = <<-RB.gsub(/^  /, "").split("\n")

    class RSpec::Core::Formatters::JsonFormatter
      def dump_summary(summary)
        total_points = summary.
          examples.
          map { |example| example.metadata[:points].to_i }.
          sum

        earned_points = summary.
          examples.
          select { |example| example.execution_result.status == :passed }.
          map { |example| example.metadata[:points].to_i }.
          sum

        score = (earned_points.to_f / total_points).round(4)

        @output_hash[:summary] = {
          :duration => summary.duration,
          :example_count => summary.example_count,
          :failure_count => summary.failure_count,
          :pending_count => summary.pending_count,
          :total_points => total_points,
          :earned_points => earned_points,
          :score => score
        }

        @output_hash[:summary_line] = [
          "\#{summary.example_count} tests",
          "\#{summary.failure_count} failures",
          "\#{earned_points}/\#{total_points} points",
          "\#{score * 100}%",
        ].join(", ")
      end

      private

      def format_example(example)
        {
          :description => example.description,
          :full_description => example.full_description,
          :status => example.execution_result.status.to_s,
          :points => example.metadata[:points],
          :file_path => example.metadata[:file_path],
          :line_number  => example.metadata[:line_number],
          :run_time => example.execution_result.run_time,
        }
      end
    end
  RB
  spec_helper_lines.insert(-2, json_formatter_lines)

  File.open("spec/spec_helper.rb", "w") do |f|
    f.puts spec_helper_lines
  end

  file "spec/factories.rb"

  # Add spec/features folder

  file "spec/features/1_something_spec.rb", <<-RB.gsub(/^    /, "")
    require "rails_helper"

    feature "A user can" do
      scenario "do a thing" do
        visit "/some_path"

        expect(page).to have_selector("p", text: "Something")
      end

      xit "see that it looks right" do
        visit "/some_path"

        Percy::Capybara.snapshot(page)

        skip "Check the Percy status on your Pull Request for visual comparison"
      end
    end
  RB

  file ".env", <<-RB.gsub(/^    /, "")
    PERCY_TOKEN=REPO_TOKEN_GOES_HERE
  RB

  copy_file "circle.yml", "circle.yml"

  # file "circle.yml", <<-YML.gsub(/^    /, "")
  #   checkout:
  #     post:
  #       - sudo apt install subversion apache2 libapache2-svn
  #       - svn export https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/trunk/spec spec --force
  #
  #   machine:
  #     ruby:
  #       version: 2.3.0
  #
  #   notify:
  #     webhooks:
  #       - url: https://grades.firstdraft.com/builds
  #
  #   test:
  #     override:
  #       - bundle exec rspec --order default --format documentation --format j --out $CIRCLE_ARTIFACTS/rspec_output.json
  # YML

  application_controller_lines = File.readlines("app/controllers/application_controller.rb")

  application_controller_lines[application_controller_lines.index("  protect_from_forgery with: :exception\n")] = "  # protect_from_forgery with: :exception\n"

  File.open("app/controllers/application_controller.rb", "w") do |file|
    file.puts application_controller_lines
  end

  gitignore_lines = File.readlines(".gitignore")

  gitignore_lines.push("", "# Ignore dotenv files", ".env*\n", "")

  gitignore_lines[gitignore_lines.index("/.bundle\n")] = "# /.bundle\n"

  File.open(".gitignore", "w") do |file|
    file.puts gitignore_lines
  end

  git :init
  git add: "-A"
  git add: ".bundle -f" # TODO Why is this necessary?
  git commit: "-m \"rails new\""
  # git branch: "target"
end
