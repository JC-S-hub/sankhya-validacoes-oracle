# Regra de negócio — Liberação Elétrica

## Objetivo

A procedure `STP_LIBERACAO_CONT_MB` controla a necessidade de liberação da nota no Sankhya.

## Exceção da Elétrica

A liberação é dispensada **somente quando as duas condições abaixo forem verdadeiras simultaneamente**:

- `TGFCAB.CODEMP = 31`
- `TGFCAB.CODCENCUS = 1040112`

A condição implementada é:

```sql
IF V_CODEMP = 31
   AND V_CODCENCUS = 1040112 THEN
    P_SUCESSO := 'S';
    P_MENSAGEM := NULL;
    RETURN;
END IF;
```

Portanto:

| Empresa | Centro de Resultado | Resultado da exceção |
|---:|---:|---|
| 31 | 1040112 | Não exige esta liberação |
| 31 | outro | Regra normal |
| outra | 1040112 | Regra normal |
| outra | outro | Regra normal |

## Regra normal

Fora da exceção:

1. Se `STATUSNOTA = 'L'`, a procedure retorna sucesso.
2. Caso contrário, retorna `P_SUCESSO = 'N'` e a mensagem `FALTA LIBERAÇÃO`.

## Tabela consultada

A procedure consulta `TGFCAB` pelo `NUNOTA` recebido e utiliza:

- `STATUSNOTA`
- `CODEMP`
- `CODCENCUS`

## Implantação

Arquivo:

`sql/03_liberacao_cont_eletrica.sql`

Recomendação: validar primeiro em homologação com pelo menos os quatro cenários da matriz acima antes de substituir a procedure em produção.
