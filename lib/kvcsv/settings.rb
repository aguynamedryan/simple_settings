# frozen_string_literal: true

require "csv"
require "forwardable"

module KVCSV
  # Settings class for managing application settings from CSV files
  #
  # This class loads settings from one or more CSV files and provides
  # read-only access to the merged configuration. CSV files should have
  # two columns: "key" and "value".
  #
  # @example Basic usage
  #   settings = KVCSV::Settings.new("config/app.csv", "config/local.csv")
  #   database_host = settings[:database_host]
  #   debug_mode = settings[:debug]
  #
  # @example Using fetch with default value
  #   port = settings.fetch(:port, 3000)
  #
  # @example CSV file format
  #   key,value
  #   database_host,localhost
  #   database_port,5432
  #   debug,true
  #   cache_enabled,false
  #
  class Settings
    extend Forwardable

    # @!method [](key)
    #   Access a setting value by key
    #   @param key [String, Symbol] The setting key to retrieve
    #   @return [String, TrueClass, FalseClass, nil] The setting value
    #
    # @!method fetch(key, default = nil)
    #   Access a setting value with optional default
    #   @param key [String, Symbol] The setting key to retrieve
    #   @param default [Object] Default value if key not found
    #   @return [Object] The setting value or default
    #
    # @!method map(&block)
    #   Iterate over settings with map
    #   @yield [key, value] Each key-value pair
    #   @return [Array] Results of the block
    #
    # @!method select(&block)
    #   Select settings matching criteria
    #   @yield [key, value] Each key-value pair
    #   @return [Hash] Filtered settings
    def_delegators :@settings, :[], :fetch, :map, :select

    # Values that are converted to true
    TRUE_VALUES = %w[t 1 true yes y].freeze

    # Values that are converted to false
    FALSE_VALUES = %w[f 0 false no n].freeze

    # Values that are converted to nil
    NIL_VALUES = %w[nil null na n/a].freeze

    # Initialize a new Settings object with one or more CSV files
    #
    # @param file_paths [Array<String>] Variable number of paths to CSV files
    # @note Non-existent files are silently ignored
    # @note Later files override values from earlier files
    #
    # @example Load from multiple files
    #   settings = KVCSV::Settings.new(
    #     "config/defaults.csv",
    #     "config/environment.csv",
    #     "config/local.csv"
    #   )
    def initialize(*file_paths)
      @settings = {}
      file_paths.compact.each do |file_path|
        next unless File.exist?(file_path)

        load_file(file_path)
      end
      symbolize_keys!
    end

    private

    def symbolize_keys!
      @settings = @settings.transform_keys(&:to_sym)
    end

    def load_file(file_path)
      CSV.foreach(file_path, headers: true) do |row|
        key = row["key"]
        value = convert_value(row["value"])
        @settings[key] = value
      end
    end

    def convert_value(value)
      return nil if value.nil? || NIL_VALUES.include?(value.downcase)
      return true if TRUE_VALUES.include?(value.downcase)
      return false if FALSE_VALUES.include?(value.downcase)

      value
    end
  end
end
