## Descrição

<!-- O que muda e porquê, do ponto de vista de quem usa o nó (EMR, laboratório, outro nó, operador). -->

## Tipo de Mudança

<!-- Marque com um "x" o que se aplica. -->

- [ ] `feat`: nova funcionalidade
- [ ] `fix`: correcção de um defeito
- [ ] `hotfix`: correcção urgente em produção
- [ ] `refactor`: mudança de estrutura sem mudança de comportamento
- [ ] `perf`: desempenho
- [ ] `docs`: documentação
- [ ] `test`: specs
- [ ] `chore`: manutenção, dependências ou release
- [ ] `ci`: GitHub Actions
- [ ] `db`: migrations

## Branch de Destino

- [ ] `dev`: integração
- [ ] `preview`: homologação
- [ ] `main`: produção (apenas a partir de `preview` ou de `hotfix/*`)

## Modo Afectado

- [ ] `local`: nó de unidade sanitária
- [ ] `national`: nó nacional
- [ ] Ambos

## Checklist

- [ ] Suite a passar nos dois modos (`SISLAB_SYNC_MODE=local` e `national`)
- [ ] `bin/rubocop` e `bin/brakeman` sem ofensas
- [ ] Contrato OpenAPI (`docs/sislab-sync/openapi.yaml`) actualizado (se a API mudou)
- [ ] Gem de referência (`clients/ruby`) e colecção Postman actualizadas (se a API mudou)
- [ ] Migrations só acrescentam colunas ou tabelas (se houver migrations)
- [ ] Strings da interface em `config/locales/pt.yml` (se a interface mudou)
- [ ] Sem `.env`, `master.key`, chaves de API ou passwords
- [ ] Sem código de debug (`binding.irb`, `pp`, `puts`)
- [ ] Mensagens de commit em Conventional Commits

## Como Testar

<!-- Comandos ou passos concretos para reproduzir a verificação. -->

1.
2.
3.

## Impacto no Deploy

<!-- Migrations, variáveis de ambiente novas no .env dos servidores (sislab-deploy), tarefas a correr depois do arranque. "Nenhum" se não houver. -->

## Contexto Adicional

<!-- Issues relacionadas, capturas de ecrã, decisões técnicas relevantes. -->
