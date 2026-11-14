# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dictionary::Catalogue do
  it "refuses to load a catalogue that is not there" do
    expect { described_class.load("db/dictionary/nao_existe.json") }
      .to raise_error(described_class::Missing, /nao_existe/)
  end

  it "says which file it is and which LOINC release its codes were checked against" do
    expect(described_class.load.describe).to match(%r{\Adb/dictionary/catalogue\.json \(LOINC [\d.]+\)\z})
  end

  describe "the catalogue shipped with the release" do
    subject(:catalogue) { described_class.load }

    def ids(entity) = catalogue.public_send(entity).map { |row| row[:id] }

    it "carries every entity the importer reads" do
      described_class::ENTITIES.each do |entity|
        expect(catalogue.public_send(entity)).to be_an(Array), "#{entity} is missing from the catalogue"
      end

      expect(catalogue.test_types).not_to be_empty
    end

    it "identifies each row once" do
      %i[departments specimen_types drugs organisms indicators test_types test_panels].each do |entity|
        expect(ids(entity)).to eq(ids(entity).uniq), "#{entity} carries the same id twice"
      end
    end

    it "links only to rows it carries, so nothing is imported half-connected" do
      {
        organism_drug_links: { organism_id: :organisms, drug_id: :drugs },
        indicator_ranges: { test_indicator_id: :indicators },
        test_type_indicator_links: { test_type_id: :test_types, indicator_id: :indicators },
        test_type_specimen_links: { test_type_id: :test_types, specimen_type_id: :specimen_types },
        test_type_organism_links: { test_type_id: :test_types, organism_id: :organisms },
        test_panel_test_type_links: { test_panel_id: :test_panels, test_type_id: :test_types }
      }.each do |link_table, columns|
        columns.each do |column, entity|
          dangling = catalogue.public_send(link_table).map { |row| row[column] } - ids(entity)
          expect(dangling).to be_empty, "#{link_table}.#{column} points at #{entity} that are not here: #{dangling}"
        end
      end
    end

    it "gives every test type a department the catalogue also carries" do
      expect(catalogue.test_types.map { |row| row[:department_id] }.uniq - ids(:departments)).to be_empty
    end

    # The catalogue is curated, so the defects the quality report exists to
    # find are not allowed back into it.
    it "carries no test a laboratory could not use" do
      reporting = catalogue.test_type_indicator_links.map { |row| row[:test_type_id] }
      collectable = catalogue.test_type_specimen_links.map { |row| row[:test_type_id] }

      expect(ids(:test_types) - reporting).to be_empty
      expect(ids(:test_types) - collectable).to be_empty
    end

    it "carries no indicator that belongs to no test" do
      expect(ids(:indicators) - catalogue.test_type_indicator_links.map { |row| row[:indicator_id] }).to be_empty
    end

    it "gives every indicator a value type the dictionary accepts" do
      expect(catalogue.indicators.map { |row| row[:value_type] }.uniq - Indicator::VALUE_TYPES).to be_empty
    end

    it "carries only LOINC codes that pass their check digit" do
      codes = %i[test_types indicators drugs].flat_map { |entity| catalogue.public_send(entity) }
                                             .filter_map { |row| row[:loinc_code] }

      expect(codes).not_to be_empty
      expect(codes.reject { |code| Dictionary::Loinc.check_digit_valid?(code) }).to be_empty
    end
  end
end
