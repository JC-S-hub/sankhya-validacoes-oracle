# Validação de período de referência

## Visão geral

Este módulo contém duas triggers Oracle PL/SQL aplicadas à tabela `TGFFIN` para controlar o campo `DTREFERENCIA` no Sankhya.

As duas regras são independentes da regra de liberação da Elétrica.

## Trigger 1 — preenchimento obrigatório

A primeira trigger exige o preenchimento de `DTREFERENCIA` quando o lançamento estiver sujeito à regra.

Ela considera exceções por TOP, natureza, tipo de lançamento, origem e demais condições específicas do ambiente.

## Trigger 2 — limite temporal

A segunda trigger impede que `DTREFERENCIA` seja anterior ao mês imediatamente anterior ao mês corrente.

O limite é calculado por:

```sql
ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)
```

Assim, são permitidos:

- mês anterior;
- mês atual;
- meses futuros.

## Arquivos

- `sql/01_valida_preenchimento_dtreferencia.sql`
- `sql/02_bloqueia_dtreferencia_antiga.sql`

## Campos e estruturas adicionais

No Sankhya, referências iniciadas por `AD_` normalmente representam campos ou tabelas adicionais do cliente.

Essas estruturas não devem ser consideradas padrão em outros ambientes.

Ao reutilizar o código:

1. confirme se cada campo `AD_*` existe;
2. confirme o tipo de dado;
3. crie o campo correspondente ou substitua-o por outro campo adequado;
4. ajuste tabelas adicionais, como `AD_CTRIGGER`, quando necessário;
5. homologue antes de usar em produção.

## Controle de ativação

As triggers utilizam a tabela adicional `AD_CTRIGGER` como mecanismo de controle.

- `NOMETGG`: nome da trigger;
- `STATUSTGG = 1`: trigger ativa.

Essa tabela é customizada e pode não existir em outro ambiente Sankhya.

## Regras principais

### Origem E

Quando o lançamento tem origem `E`, a lógica considera o relacionamento com `TGFCAB`.

Notas já liberadas não devem ser revalidadas sem necessidade, exceto quando o próprio `DTREFERENCIA` for alterado.

### Outras origens

A validação ocorre conforme as condições definidas nas triggers e o tipo de operação executada.

## Exceções previstas

Entre as exceções existentes no código estão:

- determinadas TOPs;
- determinadas naturezas;
- receitas, conforme regra implementada;
- remessas;
- renegociações;
- operações e origens específicas.

Os códigos usados são específicos do ambiente e devem ser revisados antes de qualquer reutilização.

## Matriz mínima de testes

| Cenário | Resultado esperado |
|---|---|
| Inclusão comum sem `DTREFERENCIA` | Bloqueio pela trigger de preenchimento |
| Inclusão com referência de dois meses atrás | Bloqueio pela trigger temporal |
| Inclusão com referência no mês anterior | Permitida |
| Inclusão com referência no mês atual | Permitida |
| Inclusão com referência futura | Permitida |
| Alteração de outro campo em nota já liberada | Não revalida desnecessariamente |
| Alteração de `DTREFERENCIA` em nota liberada | Revalida |
| Inclusão por remessa | Aplica exceção prevista |
| Inclusão por renegociação | Aplica exceção prevista |

## Pontos de atenção

- `SYSDATE` utiliza a data do servidor Oracle.
- Comparações com `NULL` precisam ser avaliadas com cuidado.
- Códigos de TOP, natureza e demais parâmetros são específicos do ambiente.
- Campos e tabelas `AD_*` devem sempre ser tratados como customizações.
- Teste integrações, renegociações, remessas e confirmações de nota em homologação.
