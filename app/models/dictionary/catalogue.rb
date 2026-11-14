# frozen_string_literal: true

module Dictionary
  # The catalogue shipped with the release: the dictionary a national node
  # starts life with.
  #
  # The national node is the only author of the dictionary. This file is where
  # that authorship begins — a curated list of sections, specimens, tests, the
  # indicators each test reports and their LOINC codes — and from the moment it
  # is loaded every change is made on the national node and travels to the
  # laboratories down the feed. Nothing reads a laboratory system to build it.
  #
  #   bin/rails dictionary:seed   # this file -> the node's dictionary
  #
  # Each row carries an `id`, which is its key inside the file: links and
  # ranges point at it, and the importer remembers it so that loading a newer
  # catalogue updates the entries an older one created instead of duplicating
  # them. The ids are the ones the rows had in mLab, where the catalogue was
  # first taken from, which is what lets a laboratory still running mLab be
  # translated to national codes.
  class Catalogue
    class Missing < StandardError; end

    DEFAULT_PATH = "db/dictionary/catalogue.json"

    # Everything a catalogue holds, in the order the importer reads it.
    ENTITIES = %i[
      departments specimen_types drugs organisms organism_drug_links
      indicators indicator_ranges test_types
      test_type_indicator_links test_type_specimen_links test_type_organism_links
      test_panels test_panel_test_type_links
    ].freeze

    def self.available?(path = self::DEFAULT_PATH)
      Rails.root.join(path).exist?
    end

    def self.load(path = self::DEFAULT_PATH)
      file = Rails.root.join(path)
      raise Missing, "There is no catalogue at #{path}." unless file.exist?

      new(JSON.parse(file.read, symbolize_names: true), path: path)
    end

    def initialize(data, path: nil)
      @data = data
      @path = path
    end

    def describe
      loinc = @data.dig(:meta, :loinc_version)

      [ @path || "catálogo", ("(LOINC #{loinc})" if loinc) ].compact.join(" ")
    end

    ENTITIES.each do |entity|
      define_method(entity) { rows(entity) }
    end

    private

    def rows(name)
      Array(@data[name.to_sym]).map(&:dup)
    end
  end
end
