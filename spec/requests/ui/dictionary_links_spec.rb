# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Associações do dicionário na interface", mode: :national, type: :request do
  let(:test_type) { create(:test_type, name: "Hemograma") }
  let(:indicator) { create(:indicator, name: "Hemoglobina", unit: "g/dL") }

  it "não é para um operador comum" do
    sign_in_as

    post dictionary_links_path("test_types", test_type.national_code, "indicators"),
         params: { target: indicator.national_code }

    expect(response).to redirect_to(root_path)
    expect(test_type.indicators).to be_empty
  end

  describe "sendo administrador" do
    before { sign_in_as :admin }

    it "mostra no ecrã do teste o que lhe falta e o que já tem" do
      test_type.specimen_types << create(:specimen_type, name: "Sangue total")
      indicator

      get edit_dictionary_entry_path("test_types", test_type.national_code)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Indicadores", "Tipos de amostra", "Painéis", "Sangue total")
      expect(response.body).to include("#{indicator.national_code} — Hemoglobina")
    end

    it "associa um indicador escolhido da lista e faz o teste avançar de revisão" do
      before_revision = test_type.revision

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: "#{indicator.national_code} — Hemoglobina" }

      expect(response).to redirect_to(edit_dictionary_entry_path("test_types", test_type.national_code))
      expect(test_type.reload.indicators).to contain_exactly(indicator)
      expect(test_type.revision).to be > before_revision
    end

    it "associa a partir do indicador, e é o teste — o dono da ligação — que avança" do
      before_revision = test_type.revision

      post dictionary_links_path("indicators", indicator.national_code, "test_types"),
           params: { target: test_type.national_code }

      expect(indicator.reload.test_types).to contain_exactly(test_type)
      expect(test_type.reload.revision).to be > before_revision
    end

    it "põe um teste num painel a partir do próprio teste" do
      panel = create(:test_panel, name: "Bioquímica básica")

      post dictionary_links_path("test_types", test_type.national_code, "test_panels"),
           params: { target: panel.national_code }

      expect(panel.reload.test_types).to contain_exactly(test_type)
    end

    it "aceita o nome escrito por extenso quando só uma entrada o tem" do
      indicator

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: "Hemoglobina" }

      expect(test_type.reload.indicators).to contain_exactly(indicator)
    end

    it "aceita parte do nome quando só uma entrada o contém" do
      indicator

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: "moglob" }

      expect(test_type.reload.indicators).to contain_exactly(indicator)
    end

    it "devolve a escolha quando o termo serve a várias entradas, em vez de associar ao acaso" do
      first = create(:indicator, name: "Glicose")
      second = create(:indicator, name: "Glicose")

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: "Glicose" }

      expect(test_type.reload.indicators).to be_empty
      expect(flash[:alert]).to include(first.national_code, second.national_code)
    end

    it "diz quando nada corresponde" do
      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: "Inexistente" }

      expect(test_type.reload.indicators).to be_empty
      expect(flash[:alert]).to include("Inexistente")
    end

    it "não associa uma entrada retirada" do
      retired = create(:indicator, :retired)

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: retired.national_code }

      expect(test_type.reload.indicators).to be_empty
    end

    it "não duplica uma associação que já existe" do
      test_type.indicators << indicator

      post dictionary_links_path("test_types", test_type.national_code, "indicators"),
           params: { target: indicator.national_code }

      expect(TestTypeIndicator.where(test_type: test_type).count).to eq(1)
    end

    it "remove uma associação, e o teste avança para os nós locais saberem" do
      test_type.indicators << indicator
      before_revision = test_type.reload.revision

      delete dictionary_link_path("test_types", test_type.national_code, "indicators", indicator.national_code)

      expect(test_type.reload.indicators).to be_empty
      expect(test_type.revision).to be > before_revision
      expect(Indicator.exists?(indicator.id)).to be(true)
    end

    it "cria um indicador novo já associado, como rascunho" do
      post new_dictionary_link_entry_path("test_types", test_type.national_code, "indicators"),
           params: { entry: { name: "Hematócrito", unit: "%", value_type: "Numeric" } }

      created = Indicator.find_by(name: "Hematócrito")
      expect(created).to be_draft
      expect(created.unit).to eq("%")
      expect(test_type.reload.indicators).to contain_exactly(created)
    end

    it "não deixa nada a meio quando a entrada nova é inválida" do
      post new_dictionary_link_entry_path("test_types", test_type.national_code, "indicators"),
           params: { entry: { name: "" } }

      expect(test_type.reload.indicators).to be_empty
      expect(flash[:alert]).to be_present
    end

    it "não conhece uma associação que a entidade não tem" do
      post dictionary_links_path("test_types", test_type.national_code, "drugs"), params: { target: "x" }

      expect(flash[:alert]).to be_present
    end

    it "conta as associações de cada entrada na lista e marca o que falta" do
      test_type.indicators << indicator

      get dictionary_entity_path("test_types")

      expect(response.body).to include("Associações", "Indicadores 1", "Tipos de amostra 0")
    end
  end

  describe "intervalos de referência" do
    before { sign_in_as :admin }

    it "adiciona um intervalo e faz o indicador avançar de revisão" do
      before_revision = indicator.revision

      post indicator_ranges_path(indicator.national_code),
           params: { range: { sex: "F", age_min: 18, age_max: 120, range_lower: "12", range_upper: "15.5" } }

      range = indicator.indicator_ranges.sole
      expect(range.sex).to eq("F")
      expect(range.range_upper).to eq(BigDecimal("15.5"))
      expect(indicator.reload.revision).to be > before_revision
    end

    it "recusa um intervalo invertido e diz porquê" do
      post indicator_ranges_path(indicator.national_code),
           params: { range: { sex: "Both", range_lower: "20", range_upper: "10" } }

      expect(indicator.indicator_ranges).to be_empty
      expect(flash[:alert]).to include("intervalo invertido")
    end

    it "corrige e remove um intervalo existente" do
      range = create(:indicator_range, indicator: indicator, range_lower: 1, range_upper: 2)

      patch indicator_range_path(indicator.national_code, range), params: { range: { range_upper: "3" } }
      expect(range.reload.range_upper).to eq(3)

      delete indicator_range_path(indicator.national_code, range)
      expect(IndicatorRange.exists?(range.id)).to be(false)
    end

    it "mostra os intervalos no ecrã do indicador, como se escrevem" do
      create(:indicator_range, indicator: indicator, range_lower: BigDecimal("13.5"), range_upper: 17)

      get edit_dictionary_entry_path("indicators", indicator.national_code)

      expect(response.body).to include("Intervalos de referência", 'value="13.5"', 'value="17"')
    end
  end
end
