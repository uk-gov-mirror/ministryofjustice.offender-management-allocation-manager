require 'rails_helper'
require 'delius/extractor.rb'

describe Delius::Extractor do
  it 'parses an excel spreadsheet to extract hashes' do
    filename = 'spec/fixtures/delius/delius_sample.xlsx'
    e = described_class.new(filename)
    records = e.fetch_records

    expect(records.count).to be(86)
    expect(records).to be_kind_of(Array)
    expect(records.first).to be_kind_of(Hash)

    expect(e.errors).to include('Bad record passed, missing tier')
    expect(e.errors.count).to be(6)
  end
end
