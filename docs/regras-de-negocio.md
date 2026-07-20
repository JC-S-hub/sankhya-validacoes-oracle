# Regras de negócio

## Visão geral

As duas triggers são executadas antes de inclusões ou alterações na tabela financeira `TGFFIN`. A primeira verifica a obrigatoriedade de `DTREFERENCIA`; a segunda limita a antiguidade do período informado.

## Compatibilidade de campos e estruturas adicionais

No Sankhya, colunas adicionais criadas pelo cliente normalmente são identificadas pelo prefixo `AD_`. Elas representam customizações locais e não devem ser consideradas disponíveis em todos os ambientes.

Ao adaptar qualquer código:

1. localize campos, tabelas e demais referências iniciadas por `AD_`;
2. confirme se a estrutura existe e se o tipo de dado é compatível;
3. caso não exista, crie o campo adicional necessário ou substitua-o pelo campo mais adequado à regra do novo ambiente;
4. ajuste consultas, triggers, relatórios e integrações que dependam dessa estrutura;
5. homologue a alteração antes de executar em produção.

Há uma diferença importante:

- **Campo `AD_*`**: coluna adicional vinculada a uma entidade/tabela;
- **Tabela `AD_*`**: tabela adicional criada para uma finalidade específica.

Neste projeto, `AD_CTRIGGER` é uma **tabela adicional de controle**. Ela não é garantida pelo padrão do Sankhya. Se não existir no ambiente de destino, será necessário criá-la ou substituir esse controle por outro mecanismo.

## Controle de ativação

Cada trigger consulta dinamicamente a tabela customizada `AD_CTRIGGER`:

- `NOMETGG`: nome da trigger;
- `STATUSTGG = 1`: trigger ativa;
- outro valor, registro inexistente ou falha de acesso: trigger inativa.

A consulta dinâmica evita dependência de compilação com a estrutura customizada. Como a política adotada é *fail-open*, uma falha na tabela de controle desativa a validação. Essa decisão deve ser avaliada conforme a política de risco do ambiente.

## Trigger 1 — preenchimento

A obrigatoriedade é aplicada quando todas as condições abaixo forem verdadeiras:

- a TOP não estiver na lista de exceções;
- `RECDESP` for diferente de `1`;
- a natureza não estiver na lista de exceções;
- `PROVISAO = 'N'`;
- `ORIGEM` for diferente de `P`;
- `DTREFERENCIA` estiver nula.

Os códigos de TOP e natureza são exemplos extraídos de uma regra de negócio específica e devem ser revisados.

## Trigger 2 — limite temporal

A data é normalizada para o primeiro dia do mês. O menor período permitido é calculado por:

```sql
ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)
```

Portanto, são permitidos:

- mês anterior;
- mês atual;
- meses futuros.

## Tratamento por origem

### Origem `E`

O lançamento deve possuir `NUNOTA` e a nota deve existir em `TGFCAB`.

- Durante a confirmação, a validação continua mesmo quando a data não mudou no mesmo `UPDATE`.
- Se a nota já estiver liberada (`STATUSNOTA = 'L'`), alterações em outros campos não reexecutam a regra.
- Uma alteração efetiva de `DTREFERENCIA` em nota liberada é validada.

### Outras origens

Na segunda trigger, um `UPDATE` só é validado quando `DTREFERENCIA` é efetivamente modificada.

## Exceções adicionais

| Situação | Comportamento |
|---|---|
| `RECDESP = 1` | Não aplica o limite temporal |
| Inclusão com `NUMREMESSA` | Preserva a referência gerada pela remessa |
| Inclusão com `NURENEG` | Permite preservar referência antiga da renegociação |
| `DTREFERENCIA IS NULL` na segunda trigger | Delega a obrigatoriedade à primeira trigger |

## Matriz mínima de testes

| Cenário | Resultado esperado |
|---|---|
| Inclusão comum sem `DTREFERENCIA` | Bloqueio pela primeira trigger |
| Inclusão comum com referência de dois meses atrás | Bloqueio pela segunda trigger |
| Inclusão com referência no mês anterior | Permitida |
| Inclusão com referência no mês atual | Permitida |
| Inclusão com referência futura | Permitida |
| Alteração de outro campo em nota já liberada | Não revalida a referência |
| Alteração da referência em nota já liberada | Revalida |
| Inclusão originada de remessa | Exceção ao limite temporal |
| Inclusão de renegociação | Exceção ao limite temporal |

## Pontos de atenção

1. Em Oracle, comparações e `NOT IN` com valores `NULL` não resultam em verdadeiro. Valide a nulabilidade de `CODTIPOPER`, `RECDESP`, `CODNAT`, `PROVISAO` e `ORIGEM`.
2. O uso de `SYSDATE` considera a data do servidor do banco.
3. Mensagens e códigos de `RAISE_APPLICATION_ERROR` devem ser coordenados com outras customizações.
4. Toda referência `AD_*` deve ser confirmada ou adaptada ao ambiente de destino.
5. A solução deve ser homologada com todos os processos de integração, remessa, renegociação e confirmação de nota.
