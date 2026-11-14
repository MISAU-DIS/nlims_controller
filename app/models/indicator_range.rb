# frozen_string_literal: true

# The reference interval or expected value for an indicator, narrowed by age
# and sex. A result is interpreted against these, so they travel with the
# indicator.
class IndicatorRange < ApplicationRecord
  include BumpsOwnerRevision

  SEXES = %w[Both M F].freeze

  belongs_to :indicator

  bumps_revision_of :indicator

  validates :sex, inclusion: { in: SEXES }

  # Only where a person is typing the range. mLab's catalogue carries ranges
  # that fail this, and refusing them on import or replication would lose the
  # indicator's other ranges with them; the quality report names those instead.
  validate :makes_sense, on: :editor

  # What is wrong with this range, in words, or nil. Shared by the editor, which
  # refuses it, and the quality report, which lists it.
  def problem
    if range_lower && range_upper && range_lower > range_upper
      "intervalo invertido (#{range_lower} > #{range_upper})"
    elsif range_lower.nil? && range_upper.nil? && value.blank?
      "intervalo sem limites nem valor"
    elsif age_min && age_max && age_min > age_max
      "idades invertidas (#{age_min} > #{age_max})"
    end
  end

  private

  def makes_sense
    errors.add(:base, problem) if problem
  end
end
