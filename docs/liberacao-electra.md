# Regra de negócio — Liberação ELECTRA

## Objetivo

A procedure `STP_LIBERACAO_ELECTRA_MB` determina quando uma nota deve entrar na regra de liberação da ELECTRA.

O usuário responsável pela aprovação **não é definido na procedure**. O liberador deve ser configurado diretamente na tela da Regra de Negócio do Sankhya.

## Condição de liberação

A regra exige aprovação somente quando as duas condições forem verdadeiras simultaneamente:

- `TGFCAB.CODEMP = 31`
- `TGFCAB.CODCENCUS = 1040112`

A condição implementada é:

```sql
IF V_CODEMP = 31
   AND V_CODCENCUS = 1040112 THEN
    P_SUCESSO  := 'N';
    P_MENSAGEM := 'FALTA LIBERAÇÃO - ELECTRA';
    RETURN;
END IF;
```

Para qualquer outra combinação, a procedure retorna sucesso e esta regra específica não solicita liberação.

## Matriz de comportamento

| Empresa | Centro de Resultado | Resultado |
|---:|---:|---|
| 31 | 1040112 | Exige liberação ELECTRA |
| 31 | outro | Não exige esta liberação |
| outra | 1040112 | Não exige esta liberação |
| outra | outro | Não exige esta liberação |

## Usuário liberador

O usuário que receberá a solicitação deve ser configurado na própria Regra de Negócio do Sankhya.

Por esse motivo, a procedure não contém `CODUSU` fixo e não escolhe o responsável pela aprovação.

## Tabela consultada

A procedure consulta `TGFCAB` pelo `NUNOTA` recebido e utiliza:

- `CODEMP`
- `CODCENCUS`

## Implantação

Arquivo:

`sql/03_liberacao_electra.sql`

Procedure:

`STP_LIBERACAO_ELECTRA_MB`

Após compilar a procedure, configure na Regra de Negócio do Sankhya o usuário ou liberador responsável pela autorização.

## Matriz mínima de testes

1. Empresa 31 + CR 1040112 → deve solicitar liberação.
2. Empresa 31 + outro CR → não deve solicitar esta liberação.
3. Outra empresa + CR 1040112 → não deve solicitar esta liberação.
4. Outra empresa + outro CR → não deve solicitar esta liberação.
