namespace :api_docs do
  desc 'Generate OpenAPI documentation from RSpec specs'
  task generate: :environment do
    require 'rswag/specs/rake_task'
    RSpec::Core::RakeTask.new(:api_specs) do |t|
      t.pattern = 'spec/integration/**/*_spec.rb'
      t.rspec_opts = ['--format Rswag::Specs::SwaggerFormatter', '--order defined']
    end

    Rake::Task['api_specs'].invoke
    puts '✅ OpenAPI documentation generated successfully!'
    puts "📄 View documentation at: http://localhost:3000/api-docs"
    puts "📋 YAML file: #{Rails.root.join('swagger', 'v1', 'swagger.yaml')}"
  end

  desc 'Validate OpenAPI documentation'
  task validate: :environment do
    require 'yaml'

    swagger_file = Rails.root.join('swagger', 'v1', 'swagger.yaml')

    if File.exist?(swagger_file)
      begin
        swagger = YAML.load_file(swagger_file)
        puts '✅ OpenAPI documentation is valid YAML'
        puts "   Version: #{swagger['openapi']}"
        puts "   Title: #{swagger['info']['title']}"
        puts "   API Version: #{swagger['info']['version']}"
        puts "   Paths: #{swagger['paths']&.keys&.count || 0} endpoints"
      rescue Psych::SyntaxError => e
        puts "❌ Invalid YAML: #{e.message}"
        exit 1
      end
    else
      puts "❌ OpenAPI documentation not found. Run: rake api_docs:generate"
      exit 1
    end
  end

  desc 'Generate and validate API documentation'
  task all: [:generate, :validate]
end
