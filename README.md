# Validações de período de referência no Sankhya

Projeto demonstrativo com duas triggers Oracle PL/SQL para validar o campo `DTREFERENCIA` dos lançamentos financeiros (`TGFFIN`) em ambientes Sankhya.

## Objetivo

As triggers trabalham em conjunto:

1. **Obrigatoriedade** — exige o preenchimento do período de referência nos lançamentos sujeitos à regra.
2. **Limite temporal** — impede que o período informado seja anterior ao mês imediatamente anterior ao processamento.

## Estrutura

```text
sql/
├── 01_valida_preenchimento_dtreferencia.sql
└── 02_bloqueia_dtreferencia_antiga.sql
docs/
└── regras-de-negocio.md
```

## Regras principais

- A ativação é controlada pela tabela customizada `AD_CTRIGGER`.
- Lançamentos de origem `E` são relacionados à nota em `TGFCAB`.
- Notas liberadas só são revalidadas quando `DTREFERENCIA` é efetivamente alterada.
- A segunda trigger permite o mês anterior, o mês atual e períodos futuros.
- Remessas e renegociações possuem exceções específicas para inclusão.
- Códigos de operação e natureza presentes no exemplo devem ser revisados para cada ambiente.

## Ordem sugerida de instalação

1. Revise os parâmetros marcados como **CONFIGURAÇÃO DO AMBIENTE**.
2. Execute os arquivos da pasta `sql` com um usuário autorizado.
3. Cadastre os nomes das triggers na tabela de controle `AD_CTRIGGER`.
4. Ative inicialmente em ambiente de homologação.
5. Teste inclusões e alterações de todas as origens utilizadas pela empresa.

## Importante

Este repositório é um exemplo técnico e **não é um produto oficial da Sankhya**. Estruturas customizadas, códigos de TOP, naturezas, origens e regras fiscais/financeiras variam entre ambientes. Faça backup, valide em homologação e submeta a solução à equipe responsável antes de utilizar em produção.

## Tecnologias

- Oracle Database
- PL/SQL
- ERP Sankhya
