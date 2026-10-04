# frozen_string_literal: true

# Attaching and detaching dictionary entries from the screen of either one: an
# indicator to a test, a test to a panel, a specimen type a test accepts, an
# antibiotic an organism is tested against. National node only, like every
# other change to the dictionary.
#
# Every action answers with a redirect to the entry's own screen, which Turbo
# morphs in place, so the person curating keeps their scroll position and the
# list they were working down.
class DictionaryLinksController < ApplicationController
  # The code at the start of what the picker filled in — "MOZ-TI-0012 — Hemoglobina".
  CODE = /\A\s*(\S+)/

  # How many of the entries a vague term matched are named back.
  AMBIGUOUS_SHOWN = 5

  before_action :require_admin
  before_action :set_entry
  before_action :set_association

  def create
    term = params[:target].to_s.strip
    matches = matching(term)
    return back_to_entry(alert: t(".not_found", term: term)) if matches.empty?
    return back_to_entry(alert: t(".ambiguous", term: term, names: names_of(matches))) if matches.size > 1

    target = matches.first

    @association.link!(@entry, target)
    back_to_entry(notice: t(".linked", name: target.name))
  end

  def destroy
    target = @association.other_model.find_by!(national_code: params[:target_code])
    @association.unlink!(@entry, target)

    back_to_entry(notice: t(".unlinked", name: target.name))
  end

  # A new entry, made and attached in one step — the indicator a test is
  # missing, written from the test. It is a draft like any other new entry, and
  # reaches a laboratory only once it is activated.
  def create_entry
    target = @association.other_model.new(new_entry_params)

    ApplicationRecord.transaction do
      target.save!
      @association.link!(@entry, target)
    end

    back_to_entry(notice: t(".created", code: target.national_code, name: target.name))
  rescue ActiveRecord::RecordInvalid
    back_to_entry(alert: target.errors.full_messages.to_sentence)
  end

  private

  def set_entry
    @entity_type = params[:entity_type]
    model = Dictionary.model_for(@entity_type)
    raise ActiveRecord::RecordNotFound if model.nil?

    @entry = model.find_by!(national_code: params[:national_code])
  end

  def set_association
    @association = Dictionary::Associations.find(@entity_type, params[:association])
    raise ActiveRecord::RecordNotFound if @association.nil?
  end

  # What the term can mean, most precise reading first: the code the picker
  # puts at the front, then the exact name, then any name containing it. The
  # first reading that finds anything wins, and more than one entry is handed
  # back to the person to choose from rather than guessed at — the imported
  # catalogue repeats names.
  def matching(term)
    return [] if term.blank?

    candidates = @association.candidates(@entry)
    code = term[CODE, 1]
    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"

    [
      candidates.where(national_code: code),
      candidates.where(name: term),
      candidates.where("name LIKE ?", like)
    ].each do |relation|
      found = relation.limit(AMBIGUOUS_SHOWN + 1).to_a
      return found if found.any?
    end

    []
  end

  def names_of(matches)
    shown = matches.first(AMBIGUOUS_SHOWN).map { |entry| "#{entry.national_code} #{entry.name}" }
    shown << "…" if matches.size > AMBIGUOUS_SHOWN
    shown.join("; ")
  end

  def new_entry_params
    params.require(:entry).permit(*Dictionary::Editable.attribute_names_for(@association.other_entity))
  end

  def back_to_entry(**flash)
    redirect_to edit_dictionary_entry_path(@entity_type, @entry.national_code), flash
  end
end
