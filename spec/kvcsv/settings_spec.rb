# frozen_string_literal: true

require "spec_helper"

RSpec.describe KVCSV::Settings do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_csv_file(filename, content)
    path = File.join(temp_dir, filename)
    File.write(path, content)
    path
  end

  describe "#initialize" do
    it "loads settings from a single CSV file" do
      file = create_csv_file("settings.csv", <<~CSV)
        key,value
        database_host,localhost
        database_port,5432
      CSV

      settings = described_class.new(file)
      expect(settings[:database_host]).to eq("localhost")
      expect(settings[:database_port]).to eq("5432")
    end

    it "loads settings from multiple CSV files" do
      file1 = create_csv_file("defaults.csv", <<~CSV)
        key,value
        host,default.com
        port,3000
        debug,false
      CSV

      file2 = create_csv_file("overrides.csv", <<~CSV)
        key,value
        host,override.com
        timeout,30
      CSV

      settings = described_class.new(file1, file2)
      expect(settings[:host]).to eq("override.com")
      expect(settings[:port]).to eq("3000")
      expect(settings[:debug]).to be false
      expect(settings[:timeout]).to eq("30")
    end

    it "ignores non-existent files" do
      valid_file = create_csv_file("valid.csv", <<~CSV)
        key,value
        setting,value
      CSV

      settings = described_class.new("/nonexistent/file.csv", valid_file, "/another/missing.csv")
      expect(settings[:setting]).to eq("value")
    end

    it "ignores nil file paths" do
      file = create_csv_file("settings.csv", <<~CSV)
        key,value
        foo,bar
      CSV

      settings = described_class.new(nil, file, nil)
      expect(settings[:foo]).to eq("bar")
    end

    it "symbolizes keys" do
      file = create_csv_file("settings.csv", <<~CSV)
        key,value
        string_key,value
      CSV

      settings = described_class.new(file)
      expect(settings[:string_key]).to eq("value")
      expect(settings["string_key"]).to be_nil
    end
  end

  describe "#[]" do
    let(:file) do
      create_csv_file("settings.csv", <<~CSV)
        key,value
        existing_key,value
      CSV
    end
    let(:settings) { described_class.new(file) }

    it "returns value for existing key" do
      expect(settings[:existing_key]).to eq("value")
    end

    it "returns nil for non-existing key" do
      expect(settings[:missing_key]).to be_nil
    end
  end

  describe "#fetch" do
    let(:file) do
      create_csv_file("settings.csv", <<~CSV)
        key,value
        existing_key,value
      CSV
    end
    let(:settings) { described_class.new(file) }

    it "returns value for existing key" do
      expect(settings.fetch(:existing_key)).to eq("value")
    end

    it "returns default value for non-existing key" do
      expect(settings.fetch(:missing_key, "default")).to eq("default")
    end

    it "raises error for non-existing key without default" do
      expect { settings.fetch(:missing_key) }.to raise_error(KeyError)
    end
  end

  describe "#map" do
    let(:file) do
      create_csv_file("settings.csv", <<~CSV)
        key,value
        key1,value1
        key2,value2
      CSV
    end
    let(:settings) { described_class.new(file) }

    it "maps over key-value pairs" do
      result = settings.map { |k, v| "#{k}=#{v}" }
      expect(result).to contain_exactly("key1=value1", "key2=value2")
    end
  end

  describe "#select" do
    let(:file) do
      create_csv_file("settings.csv", <<~CSV)
        key,value
        enabled,true
        disabled,false
        name,test
      CSV
    end
    let(:settings) { described_class.new(file) }

    it "selects matching key-value pairs" do
      result = settings.select { |_k, v| v == true }
      expect(result).to eq({ enabled: true })
    end
  end

  describe "value conversion" do
    context "true values" do
      %w[t 1 true yes y].each do |true_value|
        it "converts '#{true_value}' to true" do
          file = create_csv_file("settings.csv", <<~CSV)
            key,value
            bool_setting,#{true_value}
          CSV

          settings = described_class.new(file)
          expect(settings[:bool_setting]).to be true
        end
      end

      it "converts uppercase TRUE values" do
        file = create_csv_file("settings.csv", <<~CSV)
          key,value
          upper,TRUE
          mixed,True
        CSV

        settings = described_class.new(file)
        expect(settings[:upper]).to be true
        expect(settings[:mixed]).to be true
      end
    end

    context "false values" do
      %w[f 0 false no n].each do |false_value|
        it "converts '#{false_value}' to false" do
          file = create_csv_file("settings.csv", <<~CSV)
            key,value
            bool_setting,#{false_value}
          CSV

          settings = described_class.new(file)
          expect(settings[:bool_setting]).to be false
        end
      end

      it "converts uppercase FALSE values" do
        file = create_csv_file("settings.csv", <<~CSV)
          key,value
          upper,FALSE
          mixed,False
        CSV

        settings = described_class.new(file)
        expect(settings[:upper]).to be false
        expect(settings[:mixed]).to be false
      end
    end

    context "nil values" do
      %w[nil null na n/a].each do |nil_value|
        it "converts '#{nil_value}' to nil" do
          file = create_csv_file("settings.csv", <<~CSV)
            key,value
            nil_setting,#{nil_value}
          CSV

          settings = described_class.new(file)
          expect(settings[:nil_setting]).to be_nil
        end
      end

      it "converts uppercase NIL values" do
        file = create_csv_file("settings.csv", <<~CSV)
          key,value
          upper,NULL
          mixed,Nil
        CSV

        settings = described_class.new(file)
        expect(settings[:upper]).to be_nil
        expect(settings[:mixed]).to be_nil
      end

      it "converts empty values to nil" do
        file = create_csv_file("settings.csv", <<~CSV)
          key,value
          empty,
        CSV

        settings = described_class.new(file)
        expect(settings[:empty]).to be_nil
      end
    end

    it "preserves string values that don't match special values" do
      file = create_csv_file("settings.csv", <<~CSV)
        key,value
        string,regular string
        number,42
        truthy,truth
        falsy,failure
      CSV

      settings = described_class.new(file)
      expect(settings[:string]).to eq("regular string")
      expect(settings[:number]).to eq("42")
      expect(settings[:truthy]).to eq("truth")
      expect(settings[:falsy]).to eq("failure")
    end
  end

  describe "file merging" do
    it "later files override earlier files" do
      file1 = create_csv_file("first.csv", <<~CSV)
        key,value
        setting1,first
        setting2,original
      CSV

      file2 = create_csv_file("second.csv", <<~CSV)
        key,value
        setting2,overridden
        setting3,new
      CSV

      settings = described_class.new(file1, file2)
      expect(settings[:setting1]).to eq("first")
      expect(settings[:setting2]).to eq("overridden")
      expect(settings[:setting3]).to eq("new")
    end
  end
end
