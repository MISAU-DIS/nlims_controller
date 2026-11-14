# frozen_string_literal: true

module DictionaryHelper
  # A decimal column as a person would type it: 13.5, not 0.135e2, and 12, not
  # 12.0 — the form shows back exactly what the range means.
  def plain_number(value)
    return value unless value.is_a?(BigDecimal)

    value.to_s("F").delete_suffix(".0")
  end
end
