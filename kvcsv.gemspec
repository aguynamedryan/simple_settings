# frozen_string_literal: true

require_relative "lib/kvcsv/version"

Gem::Specification.new do |spec|
  spec.name = "kvcsv"
  spec.version = KVCSV::VERSION
  spec.authors = ["Ryan Duryea"]
  spec.email = ["aguynamedryan@gmail.com"]

  spec.summary = "Key-value pairs from stackable CSV files"
  spec.description = "A lightweight Ruby gem for managing application settings from CSV files with automatic type conversion and multi-file support."
  spec.homepage = "https://github.com/aguynamedryan/kvcsv"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aguynamedryan/kvcsv"
  spec.metadata["changelog_uri"] = "https://github.com/aguynamedryan/kvcsv/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "csv", "~> 3.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
