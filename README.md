# Kvcsv

A lightweight Ruby gem for managing application settings from CSV files. Kvcsv provides a simple, read-only interface for loading configuration from one or more CSV files with automatic type conversion for boolean and nil values.

## Features

- Load settings from one or more CSV files
- Automatic type conversion (true/false/nil)
- Simple key-based access with symbol keys
- Support for default values via `fetch`
- Enumerable interface (map, select, etc.)
- Later files override earlier ones for easy environment-specific configuration

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add kvcsv
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install kvcsv
```

## Usage

### CSV File Format

Create CSV files with two columns: `key` and `value`:

```csv
key,value
database_host,localhost
database_port,5432
debug,true
cache_enabled,false
api_key,sk-1234567890
timeout,30
environment,production
```

### Basic Usage

```ruby
require 'kvcsv'

# Load from a single file
settings = KVCSV::Settings.new("config/app.csv")

# Access settings
database_host = settings[:database_host]  # => "localhost"
debug_mode = settings[:debug]             # => true (automatically converted)
missing_key = settings[:missing_key]      # => nil

# Use fetch with defaults
port = settings.fetch(:port, 3000)        # => 3000 (default value)
```

### Loading Multiple Files

Later files override values from earlier files:

```ruby
# config/defaults.csv has debug=false
# config/production.csv has debug=true
settings = KVCSV::Settings.new(
  "config/defaults.csv",
  "config/production.csv"
)

settings[:debug]  # => true (from production.csv)
```

### Type Conversion

The following values are automatically converted:

- **True values:** `t`, `1`, `true`, `yes`, `y` (case-insensitive)
- **False values:** `f`, `0`, `false`, `no`, `n` (case-insensitive)
- **Nil values:** `nil`, `null`, `na`, `n/a` (case-insensitive), or empty values

```csv
key,value
feature_enabled,true
verbose,yes
disabled,0
optional_field,nil
```

```ruby
settings = KVCSV::Settings.new("config.csv")
settings[:feature_enabled]  # => true
settings[:verbose]          # => true
settings[:disabled]         # => false
settings[:optional_field]   # => nil
```

### Enumerable Interface

Settings objects support enumerable methods:

```ruby
# Map over settings
urls = settings.map { |key, value| value if key.to_s.end_with?("_url") }.compact

# Select specific settings
database_settings = settings.select { |key, _| key.to_s.start_with?("database_") }

# Check for existence
settings.fetch(:required_key)  # Raises KeyError if not found
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aguynamedryan/kvcsv.
