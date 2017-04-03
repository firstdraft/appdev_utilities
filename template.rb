require "open-uri"
require "pry"

binding.pry;

def path_to_file(filename)
  File.join(File.expand_path(File.dirname(__FILE__)), "files", filename)
end

def render_file(filename)
  File.open(path_to_file(filename))
end

# Add a rails engine to provide /console in all apps
# Add a rails engine to provide /git in all apps
# Add a rails engine to provide /rails in all apps

# Create branch for -target
# Create deploy script to push target branch to heroku

# Create/modify bin/setup
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

gem_group :development, :test do
  gem "dotenv-rails"
end

gem_group :development do
  gem "awesome_print"
  gem "better_errors"
  gem "binding_of_caller"
  gem "letter_opener"
  gem "pry-rails"
  gem "wdm", platforms: [:mingw, :mswin, :x64_mingw]
end

gem_group :test do
  gem "capybara"
  gem "factory_girl_rails"
  gem "rspec-rails"
  gem "webmock"
end

after_bundle do
  environment \
    "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }",
    env: "development"

  application \
    <<-RB.gsub(/^      /, "")
      config.generators do |g|
            g.test_framework nil
            g.factory_girl false
          end
    RB

  remove_file "public/favicon.ico"
  file "public/favicon.ico", render_file("favicon.ico")

  remove_file "README.md"
  file "README.md", render_file("README.md")

  prepend_file "README.md" do
    <<-MD.gsub(/^      /, "")
      # #{@app_name.titleize}

    MD
  end

  file ".env", render_file(".env")

  append_file ".gitignore" do
    <<-EOF.gsub(/^      /, "")

      # Ignore dotenv files
      /.env*
    EOF
  end

  generate "rspec:install"

  remove_file ".rspec"
  file ".rspec", render_file(".rspec")

  inside "spec" do
    inject_into_file "rails_helper.rb", after: "require 'rspec/rails'\n" do
      <<-RUBY.gsub(/^        /, "")
        require "capybara/rails"
        require "capybara/rspec"
      RUBY
    end
  end

  prepend_file "spec/spec_helper.rb" do
    "require \"factory_girl_rails\""
  end

  inside "spec" do
    inject_into_file "spec_helper.rb", after: "RSpec.configure do |config|\n" do
      <<-RUBY.gsub(/^      /, "")
        config.include FactoryGirl::Syntax::Methods

        config.backtrace_exclusion_patterns = [
          /\\/lib\\d*\\/ruby\\//,
          /bin\\//,
          /gems/,
          /spec\\/spec_helper\\.rb/,
          /lib\\/rspec\\/(core|expectations|matchers|mocks)/
        ]

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

            @output_hash[:summary] = {
              :duration => summary.duration,
              :example_count => summary.example_count,
              :failure_count => summary.failure_count,
              :pending_count => summary.pending_count,
              :total_points => total_points,
              :earned_points => earned_points,
              :score => earned_points.to_f / total_points
            }

            @output_hash[:summary_line] = [
              "\#{summary.example_count} tests",
              "\#{summary.failure_count} failures",
              "\#{earned_points}/\#{total_points} points",
              "\#{(earned_points.to_f / total_points) * 100}%",
            ].join(", ")
          end

          private

          def format_example(example)
            {
              :description => example.description,
              :full_description => example.full_description,
              :hint => example.metadata[:hint],
              :status => example.execution_result.status.to_s,
              :points => example.metadata[:points],
              :file_path => example.metadata[:file_path],
              :line_number  => example.metadata[:line_number],
              :run_time => example.execution_result.run_time,
            }
          end
        end
      RUBY
    end
  end

  file "spec/factories.rb"

  file "spec/features/1_home_page_spec.rb", <<-RB.gsub(/^    /, "")
    require "rails_helper"

    feature "The home page" do
      it "displays a greeting", points: 0, hint: "Should say hi" do
        visit "/"

        expect(page).to have_selector("p", text: "hi")
      end
    end
  RB

  file "lib/tasks/grade.rake", render_file("grade.rake")

  file ".firstdraft_project.yml", render_file(".firstdraft_project.yml")

  gsub_file "app/controllers/application_controller.rb",
            /protect_from_forgery with: :exception/, "# protect_from_forgery with: :exception"

  git :init
  git add: "-A"
  git commit: "-m \"rails new\""
end
