# frozen_string_literal: true

module Dictionary
  # The relationships an administrator edits from an entry's own screen, seen
  # from either end.
  #
  # Dictionary::LINKS says which entry owns each link, because that is the one
  # whose revision moves and the one the feed ships it inside. The person
  # curating the catalogue does not think in owners: an indicator found without
  # a test is fixed from the indicator, and a test that belongs in a panel is
  # put there from the test. So every link is offered from both of its ends, and
  # whichever end it is changed from, the same join row is written and the
  # owner's revision moves by the join model's own callback.
  module Associations
    # Links an entry may perfectly well have none of: most tests are not
    # cultures, belong to no panel, and an organism can be named before its
    # antibiogram is. Every other empty link is one the quality report names,
    # and the screens mark it.
    OPTIONAL = {
      "test_types" => %w[organisms test_panels],
      "organisms" => %w[drugs]
    }.freeze

    Association = Struct.new(:name, :entity_type, :join_model_name, :own_key, :other_key, :other_entity,
                             keyword_init: true) do
      def join_model = join_model_name.constantize
      def other_model = Dictionary.model_for!(other_entity)

      def expected? = !OPTIONAL.fetch(entity_type, []).include?(name)

      def linked(entry)
        other_model.where(id: join_model.where(own_key => entry.id).select(other_key)).order(:name)
      end

      # Retired entries cannot be newly attached to anything: a local node would
      # receive a link to something it has been told is gone.
      def candidates(entry)
        other_model.where.not(status: DictionaryEntry::RETIRED)
                   .where.not(id: join_model.where(own_key => entry.id).select(other_key))
                   .order(:name)
      end

      def linked?(entry, target)
        join_model.exists?(own_key => entry.id, other_key => target.id)
      end

      def link!(entry, target)
        return false if linked?(entry, target)

        join_model.create!(own_key => entry.id, other_key => target.id)
      end

      # destroy, not delete: the join model's callback is what tells the owner,
      # and through it every local node, that the link is gone.
      def unlink!(entry, target)
        join_model.where(own_key => entry.id, other_key => target.id).destroy_all.any?
      end

      # How many links each of `ids` carries, in one query, for a list screen.
      def counts_for(ids)
        join_model.where(own_key => ids).group(own_key).count
      end
    end

    def self.for(entity_type)
      entity_type = entity_type.to_s

      owned = Dictionary.links_for(entity_type).map do |link|
        Association.new(name: link.name.to_s, entity_type: entity_type, join_model_name: link.join_model_name,
                        own_key: link.owner_key, other_key: link.target_key, other_entity: link.target_entity)
      end

      referring = Dictionary::LINKS.flat_map do |owner_entity, links|
        links.select { |link| link.target_entity == entity_type }.map do |link|
          Association.new(name: owner_entity, entity_type: entity_type, join_model_name: link.join_model_name,
                          own_key: link.target_key, other_key: link.owner_key, other_entity: owner_entity)
        end
      end

      owned + referring
    end

    def self.find(entity_type, name)
      self.for(entity_type).find { |association| association.name == name.to_s }
    end
  end
end
