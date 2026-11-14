# frozen_string_literal: true

# The reference intervals of an indicator, edited on the indicator's own
# screen. National node only. A range has no revision of its own, so each
# change moves the indicator's, which is what carries it to the local nodes.
class IndicatorRangesController < ApplicationController
  before_action :require_admin
  before_action :set_indicator
  before_action :set_range, only: %i[update destroy]

  def create
    save(@indicator.indicator_ranges.new(range_params), t(".created"))
  end

  def update
    @range.assign_attributes(range_params)
    save(@range, t(".updated"))
  end

  def destroy
    @range.destroy!
    back_to_indicator(notice: t(".destroyed"))
  end

  private

  def save(range, notice)
    if range.save(context: :editor)
      back_to_indicator(notice: notice)
    else
      back_to_indicator(alert: range.errors.full_messages.to_sentence)
    end
  end

  def set_indicator
    @indicator = Indicator.find_by!(national_code: params[:national_code])
  end

  def set_range
    @range = @indicator.indicator_ranges.find(params[:id])
  end

  def range_params
    params.require(:range).permit(:sex, :age_min, :age_max, :range_lower, :range_upper, :value, :interpretation)
  end

  def back_to_indicator(**flash)
    redirect_to edit_dictionary_entry_path("indicators", @indicator.national_code), flash
  end
end
