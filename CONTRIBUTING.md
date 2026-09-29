# Guia de Contribuição

Este documento descreve o fluxo de branches, as regras de commits e de pull requests
e as verificações exigidas antes de cada merge no SISLAB Sync.

---

## Visão Geral das Branches

```
feat/minha-feature ──┐
fix/uma-correccao ───┼──► dev ──► preview ──► main ──► release vX.Y.Z
docs/, chore/, ci/ ──┘                         ▲
                                  hotfix/* ────┘ (e de volta a dev)
```

| Branch | Finalidade | Imagem publicada |
|---|---|---|
| `feat/*` | Novas funcionalidades | Não |
| `fix/*`, `docs/*`, `chore/*`, `ci/*`, `test/*` | Correcções, documentação, manutenção, CI e testes | Não |
| `hotfix/*` | Correcções urgentes em produção | Não |
| `dev` | Integração contínua | `sislab_sync:dev` a cada merge |
| `preview` | Homologação | `sislab_sync:preview` a cada merge |
| `main` | Produção | `sislab_sync:vX.Y.Z` quando a release é publicada |

Não há branches por laboratório. A mesma imagem serve todos os nós, e o que distingue
um nó é o seu `.env`: o modo (`local` ou `national`), o código da unidade sanitária e
o endereço do nó nacional. Uma diferença de comportamento entre unidades resolve-se
com configuração ou com dados do dicionário, nunca com uma branch.

### Como o código chega aos servidores

O workflow `.github/workflows/publish-image.yml` publica as imagens em
`ghcr.io/misau-dis/sislab_sync`. A versão executada em cada laboratório é definida
pela chave `sync:` do `instalacoes.yml` no
[MISAU-DIS/sislab-deploy](https://github.com/MISAU-DIS/sislab-deploy), e o
`sislab-agent` de cada servidor aplica-a.

- Os servidores de testes usam `sync: dev` e recebem cada merge em `dev`.
- Os servidores de homologação usam `sync: preview` e recebem cada merge em `preview`.
- Para actualizar um laboratório, publique a release `vX.Y.Z` e altere a entrada do
  laboratório no `instalacoes.yml`.

---

## Descrição de Cada Branch

### `feat/*`, `fix/*` e as restantes de trabalho

Criadas a partir de `dev`, com um nome curto em kebab-case, em inglês como o código:

```
feat/referral-transport-time
fix/arriving-sample-belongs-to-this-unit
docs/contributing
ci/publish-image
```

**Ciclo de vida:**
1. Criada a partir de `dev`
2. Desenvolvida e testada localmente
3. Pull request para `dev`
4. Removida depois do merge

### `hotfix/*` — Correcções urgentes

Para um defeito em produção que não pode esperar pelo ciclo normal.

1. Criada a partir de `main`
2. Pull request para `main`, seguido de uma release de patch (`vX.Y.Z+1`)
3. Pull request da mesma branch para `dev`, para a correcção não se perder
4. Removida depois dos dois merges

### `dev` — Integração

Recebe os pull requests das branches de trabalho. Cada merge publica `:dev`, que os
servidores de testes aplicam sozinhos no ciclo seguinte do agente (cerca de 15
minutos entre o merge e o nó actualizado).

> Nunca faça commit directo em `dev`. Use sempre um pull request.

### `preview` — Homologação

Recebe `dev` por pull request quando um conjunto de mudanças está pronto para ser
validado. Cada merge publica `:preview` para os servidores de homologação.

### `main` — Produção

Recebe `preview` (ou um `hotfix/*`) por pull request. Uma release só é publicada a
partir de um commit de `main`.

> Nunca faça commit directo em `main`.

---

## Publicar uma Release

A versão aparece em três ficheiros, que têm de coincidir. O contrato OpenAPI declara
a mesma versão que o nó, a suite verifica-o, e o nó reporta essa string no
`/api/v3/health`, no `CapabilityStatement` FHIR e em cada heartbeat.

| Ficheiro | Conteúdo |
|---|---|
| `VERSION` | `4.1.0` |
| `docs/sislab-sync/openapi.yaml` | `info.version: 4.1.0` |
| `clients/ruby/lib/sislab_sync_client/version.rb` | `VERSION = "4.1.0"` |

1. Num branch `chore/release-4.1.0` a partir de `main`, actualize os três ficheiros,
   corra `bundle install` (o `Gemfile.lock` regista a versão da gem de referência) e
   actualize os exemplos do `README.md` que mostram a versão.
2. Commit `chore(release): 4.1.0`, pull request para `main` e merge.
3. Publique a release sobre o commit do merge, com um token pessoal. Releases criadas
   pelo `GITHUB_TOKEN` de outro workflow não disparam a publicação:
   ```bash
   gh release create v4.1.0 --target <sha do merge em main> --notes-file notas.md
   ```
4. Aguarde o workflow *Publish image*, que publica `:v4.1.0` e anexa
   `sislab-sync-v4.1.0.tar.gz` à release, para as instalações sem internet.
5. Abra o pull request no `sislab-deploy` com `sync: v4.1.0` nas entradas a actualizar.

A numeração segue [SemVer](https://semver.org/lang/pt-BR/): `MAJOR` para uma mudança
incompatível no contrato de uma das três fronteiras (EMR, SISLAB, entre nós), `MINOR`
para funcionalidade nova compatível, `PATCH` para correcções.

---

## Regras de Commits

### Formato

Todos os commits seguem **Conventional Commits**, escritos em **inglês**, como o
código e os comentários:

```
<tipo>(<escopo>): <descrição curta>

[corpo opcional]

[rodapé opcional]
```

**Exemplos do histórico:**
```
fix(referrals): give an arriving sample to the unit it was referred to
feat(fhir): serve the EMR endpoints as a FHIR R4 façade
docs(api): describe the facility register, and teach the client gem about it
test: prove no events are lost or duplicated across an outage
```

### Linha de título (obrigatória)

- `tipo(escopo): descrição`, com o escopo opcional
- Máximo de **72 caracteres**
- Imperativo presente, em minúsculas: "give", não "gave", "gives" nem "Give"
- Sem ponto final
- Descreve o efeito para quem usa o nó, não o ficheiro que mudou: "refuse a parcel
  whose destination unit cannot be determined", e não "update referral controller"

### Corpo (opcional)

- Separado do título por uma linha em branco, com linhas de até 72 caracteres
- Explica **o quê** e **porquê**. O diff já mostra o como.
- Obrigatório quando a razão não é óbvia pelo título: uma escolha entre alternativas,
  uma restrição do MySQL/MariaDB, um comportamento de outro sistema

### Rodapé (opcional)

- Referência a issues: `Refs: #123`
- Mudança incompatível: `BREAKING CHANGE: <o que um cliente tem de mudar>`

### Tipos

| Tipo | Quando usar |
|---|---|
| `feat` | Funcionalidade nova, na API, na interface ou num job |
| `fix` | Correcção de um defeito |
| `docs` | Apenas documentação: README, contrato OpenAPI, colecção Postman, guias |
| `test` | Apenas specs |
| `refactor` | Mudança de estrutura sem mudança de comportamento |
| `perf` | Melhoria de desempenho |
| `style` | Formatação, sem mudança de lógica |
| `chore` | Manutenção: dependências, configuração, releases |
| `ci` | Workflows do GitHub Actions |
| `db` | Migrations sem outra mudança de código |
| `revert` | Reversão de um commit anterior |

### Escopos

O escopo é opcional mas recomendado. Nomeia a área do domínio, não a pasta:

```
intake       → admissão de pedidos (EMR, FHIR)
lifecycle    → estados do pedido e dos testes, status_events
referrals    → referências entre unidades e laboratórios
sync         → outbox, push, pull, routing entre nós
dictionary   → dicionário nacional, importação do mLab, LOINC
register     → registo nacional de unidades e laboratórios
identity     → identidade do nó (modo, unidade)
fhir         → fachada FHIR R4
api          → contrato OpenAPI, envelope, erros, chaves de API
ui           → interface web
audit        → trilho de auditoria
docker       → Dockerfile, compose, entrypoint
production   → configuração de produção
release      → preparação de uma versão
deps         → Gemfile, importmap
spec         → infra-estrutura da suite
```

### O que incluir num commit

**Inclua:**
- Uma mudança lógica e coesa
- A migration junto do código que a exige
- Os specs junto do código que testam
- O contrato OpenAPI, a colecção Postman e a gem de referência junto da mudança de
  API que os afecta
- As strings novas da interface em `config/locales/pt.yml`

**Não inclua:**
- Várias mudanças sem relação entre si
- Código de debug (`binding.irb`, `pp`, `puts`)
- `.env`, `config/master.key`, chaves de API ou passwords
- Um `db/schema.rb` alterado sem migration (ver [Base de dados](#base-de-dados))
- Formatação misturada com mudanças de lógica

### Boas práticas

- Commits pequenos e frequentes: facilitam a revisão e a reversão.
- Cada commit deixa a suite a passar nos dois modos.
- `git pull --rebase` antes do push, para evitar merge commits desnecessários.
- `git add -p` para separar mudanças misturadas no mesmo ficheiro.

---

## Antes de Abrir o Pull Request

### A suite, nos dois modos

A mesma imagem corre como nó local ou nacional, e cada modo tem rotas, jobs e
endpoints próprios. O CI corre a suite nos dois; corra-a também localmente:

```bash
bin/rubocop
bin/brakeman --no-pager
bundle exec bundler-audit check --update

SISLAB_SYNC_MODE=local    bundle exec rspec
SISLAB_SYNC_MODE=national bundle exec rspec
```

Um endpoint que existe apenas num modo declara-o no spec com `mode: :local` ou
`mode: :national` (`spec/support/run_mode.rb`).

### O contrato da API

`docs/sislab-sync/openapi.yaml` é o contrato publicado em `/api-docs`, e a suite
valida contra ele cada pedido e cada resposta que provoca
(`spec/support/openapi_contract.rb`). Uma mudança num endpoint `/api/v3` leva, no
mesmo pull request:

- o path e os schemas actualizados em `openapi.yaml`;
- a gem de referência (`clients/ruby`), se o endpoint pertence a um dos perfis
  `Emr`, `Lab` ou `Node`;
- a colecção Postman, se o endpoint aparece nela.

`spec/contracts/openapi_spec.rb` falha quando uma rota, um estado, um código de erro
ou um tipo de evento existe no código e não no contrato, ou ao contrário.

A fachada FHIR (`/fhir/r4`) fica fora do `openapi.yaml`. O seu contrato é o
`CapabilityStatement` gerado em `/fhir/r4/metadata`.

### Base de dados

- **Migrations só acrescentam.** O `sislab-agent` repõe a imagem anterior quando a
  nova não fica saudável, mas as migrations não se revertem, e a versão anterior
  passa a correr sobre o schema novo. Acrescente colunas e tabelas numa release, e
  deixe renomeações e remoções para uma release posterior.
- Teste a migration com MySQL 8.4. Os servidores podem ter MariaDB, que também é
  suportado.
- Se o `db/schema.rb` aparecer alterado depois de correr a suite sem ter mexido numa
  migration, é deriva da base de testes local: reverta o ficheiro e reconstrua-a com
  `bin/rails db:test:prepare`.

### Comentários e documentação

Os comentários e a documentação descrevem o código como ele está e porque é assim,
no presente. "Uma amostra referida pertence à unidade de destino", e não "a amostra
passou a pertencer" nem "já não pertence à origem". A história da mudança fica na
mensagem de commit.

---

## Regras de Pull Request

- A descrição segue o template [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md),
  que o GitHub preenche ao abrir o PR.
- Pelo menos **uma aprovação** antes do merge.
- O CI (`lint` e `spec` nos dois modos) tem de estar verde.
- A branch está actualizada com a de destino, e os conflitos resolvidos localmente.
- Um pull request por mudança lógica. Várias correcções independentes vão em PRs
  separados.
- A branch é apagada depois do merge.

### O template

- **Descrição:** o que muda e porquê, do ponto de vista de quem usa o nó.
- **Tipo de mudança** e **branch de destino** (normalmente `dev`).
- **Modo afectado:** `local`, `national` ou ambos. Diz ao revisor onde testar.
- **Checklist:** marque apenas o que verificou. "Contrato OpenAPI actualizado" só
  quando há mudança na API.
- **Como testar:** comandos ou passos concretos, não descrições vagas.
- **Impacto no deploy:** migrations, variáveis de ambiente novas ou tarefas a correr
  depois do arranque. É o que quem actualiza os laboratórios precisa de saber.

---

## Imagens Publicadas

| Evento | Imagem |
|---|---|
| merge em `dev` | `ghcr.io/misau-dis/sislab_sync:dev` |
| merge em `preview` | `ghcr.io/misau-dis/sislab_sync:preview` |
| release `vX.Y.Z` publicada | `ghcr.io/misau-dis/sislab_sync:vX.Y.Z` (+ `.tar.gz` na release) |

Todas levam também `:sha-<commit>`.

---

## Resumo Visual

```
feat/*, fix/* ──────────────────────────────────► (removida depois do merge)
       │ PR
       ▼
      dev ──(imagem :dev → servidores de testes)
       │ PR
       ▼
    preview ──(imagem :preview → homologação)
       │ PR
       ▼
      main ──(release vX.Y.Z → imagem :vX.Y.Z; laboratórios via sislab-deploy)

hotfix/* ──► main (+ release de patch) e dev
```
