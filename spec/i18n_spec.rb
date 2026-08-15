require "rails_helper"

RSpec.describe I18n do
  def flattened_keys(value, prefix = nil)
    return [ prefix ] unless value.is_a?(Hash)

    value.flat_map do |key, child|
      flattened_keys(child, [ prefix, key ].compact.join("."))
    end
  end

  it "keeps English, Brazilian Portuguese, and Spanish structurally complete" do
    dictionaries = %w[en pt-BR es].to_h do |locale|
      yaml = YAML.safe_load_file(Rails.root.join("config/locales/#{locale}.yml"))
      [ locale, flattened_keys(yaml.fetch(locale)).sort ]
    end

    expect(dictionaries.fetch("pt-BR")).to eq(dictionaries.fetch("en"))
    expect(dictionaries.fetch("es")).to eq(dictionaries.fetch("en"))
  end
end
