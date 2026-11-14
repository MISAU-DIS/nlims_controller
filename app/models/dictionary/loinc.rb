# frozen_string_literal: true

module Dictionary
  # LOINC curation.
  #
  # A MOZ- code means nothing outside this country. The LOINC code beside it is
  # what lets a FHIR or HL7 façade over these models be read by anybody else,
  # and a result leaving Mozambique be understood without a translation table.
  # The shipped catalogue carries the codes that could be decided with
  # certainty; the rest, and every entry created afterwards, is curated here.
  #
  # The codes cannot be derived. Somebody who knows the laboratory has to decide
  # that "Hemograma completo" is the LOINC panel it looks like, and no amount of
  # string matching makes that decision for them. What can be automated is
  # everything either side of it: measuring the gap, proposing candidates worth
  # looking at, and applying a decision once it has been made.
  module Loinc
    # Digits, a hyphen, and a Mod-10 check digit. Anything else is a
    # transcription error, and a wrong LOINC code is worse than none: it says
    # confidently that a test is something it is not. LOINC issues the numbers
    # in sequence and passed 100000 some releases ago, so the body is not held
    # to five digits; seven is the most the standard allows for.
    CODE_FORMAT = /\A\d{1,7}-\d\z/

    # The entity types LOINC has codes for: what is ordered, what is measured,
    # and the susceptibility of an organism to a drug. LOINC names neither
    # organisms nor specimens — those are SNOMED CT's — and a laboratory
    # section or a rejection reason is administrative. Counting any of them
    # would make coverage look permanently unachievable.
    CURATED_ENTITIES = %w[test_types indicators drugs].freeze

    def self.curated?(entity_type)
      CURATED_ENTITIES.include?(entity_type.to_s)
    end

    def self.valid_code?(code)
      CODE_FORMAT.match?(code.to_s)
    end

    # LOINC's own Mod-10 check digit, so a code mistyped by one character is
    # refused here rather than travelling to every laboratory in the country.
    #
    # Counting from the right of the body, the digits in odd positions — the
    # rightmost first — are doubled. That is the opposite of the Luhn variant
    # used for card numbers, and getting it the wrong way round rejects every
    # valid code, so: 718-7, 2160-0 and 4544-3 all have to pass.
    def self.check_digit_valid?(code)
      return false unless valid_code?(code)

      body, check = code.split("-")

      sum = body.chars.map(&:to_i).reverse.each_with_index.sum do |digit, index|
        next digit if index.odd?

        doubled = digit * 2
        doubled > 9 ? doubled - 9 : doubled
      end

      ((10 - (sum % 10)) % 10) == check.to_i
    end
  end
end
