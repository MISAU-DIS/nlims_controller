# frozen_string_literal: true

module Dictionary
  # The dictionary a national node starts life with.
  #
  # It loads the catalogue shipped with the release and publishes it, because a
  # dictionary nobody promoted reaches no laboratory. From then on the
  # dictionary is edited on the national node by hand; this runs once at
  # installation, and again only when a release ships a newer catalogue — which
  # then overwrites the fields it carries, so it is not for a node whose
  # dictionary has moved on by hand.
  #
  # Re-runnable, like the import it wraps: entries are matched by their key in
  # the catalogue, so a second run changes nothing it did the first time.
  class Seed
    ACTOR = "catálogo inicial"

    # A laboratory that cannot say why it refused a sample writes the reason in
    # a note nobody can count, so the release ships a starting set. They are ordinary dictionary entries from
    # the moment they exist: add to them, rename or retire them like any other.
    REJECTION_REASONS = [
      "Amostra hemolisada",
      "Amostra coagulada",
      "Volume insuficiente",
      "Recipiente ou anticoagulante inadequado",
      "Tubo mal identificado",
      "Amostra sem identificação",
      "Amostra recebida sem requisição",
      "Cadeia de frio quebrada",
      "Amostra derramada em trânsito",
      "Tempo entre colheita e recepção excedido"
    ].freeze

    attr_reader :source, :importer, :promotion, :reasons_created

    def initialize(source: nil, actor: ACTOR, skip_blocked: false)
      @source = source || Catalogue.load
      @actor = actor
      @skip_blocked = skip_blocked
      @reasons_created = 0
    end

    def call
      @importer = CatalogueImporter.new(source: @source).call
      @reasons_created = add_rejection_reasons
      @promotion = Promotion.new(actor: @actor, skip_blocked: @skip_blocked).call

      self
    end

    def published
      Dictionary::ENTITIES.each_key.sum { |entity_type| Dictionary.model_for!(entity_type).active.count }
    end

    private

    # Drafts, like everything the import makes, so the promotion is what
    # publishes them and the history says who did it.
    def add_rejection_reasons
      REJECTION_REASONS.count do |name|
        next false if RejectionReason.where(name: name).exists?

        RejectionReason.create!(name: name, status: DictionaryEntry::DRAFT, status_actor: @actor)
        true
      end
    end
  end
end
