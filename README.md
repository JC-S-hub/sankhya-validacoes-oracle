# Regras, validações e automações Sankhya / Oracle

Repositório para centralizar customizações técnicas usadas no Sankhya ERP, principalmente regras de negócio, procedures, triggers e validações implementadas em Oracle PL/SQL.

O objetivo deste repositório não é documentar uma única regra, mas manter cada customização separada, com seu código, finalidade, exceções e critérios de implantação.

## Estrutura atual

```text
sql/
├── 01_valida_preenchimento_dtreferencia.sql
├── 02_bloqueia_dtreferencia_antiga.sql
└── 03_liberacao_cont_eletrica.sql

docs/
├── periodo-referencia.md
└── liberacao-eletrica.md
```

## Módulos

### 1. Validação de período de referência

Controla o preenchimento e o limite temporal de `DTREFERENCIA` em lançamentos financeiros.

Arquivos:

- `sql/01_valida_preenchimento_dtreferencia.sql`
- `sql/02_bloqueia_dtreferencia_antiga.sql`
- `docs/periodo-referencia.md`

Principais objetos envolvidos:

- `TGFFIN`
- `TGFCAB`
- `AD_CTRIGGER`

### 2. Regra de liberação da Elétrica

Controla a necessidade de liberação de nota por meio da procedure `STP_LIBERACAO_CONT_MB`.

A exceção atual dispensa esta liberação somente quando as duas condições forem atendidas simultaneamente:

- `CODEMP = 31`
- `CODCENCUS = 1040112`

Arquivos:

- `sql/03_liberacao_cont_eletrica.sql`
- `docs/liberacao-eletrica.md`

Principais objetos envolvidos:

- `TGFCAB`
- `STATUSNOTA`
- `CODEMP`
- `CODCENCUS`

## Convenção do repositório

Cada nova regra deve, sempre que possível, possuir:

1. um arquivo SQL próprio em `sql/`;
2. uma documentação própria em `docs/`;
3. descrição das tabelas e campos utilizados;
4. descrição de exceções;
5. matriz mínima de testes;
6. indicação clara de qualquer dependência de campos ou tabelas customizadas.

## Campos e tabelas adicionais `AD_*`

No Sankhya, campos e tabelas iniciados por `AD_` normalmente representam customizações do cliente.

Essas estruturas não são garantidas em outros ambientes.

Quem reutilizar qualquer código deste repositório deve:

- identificar referências `AD_*`;
- confirmar se elas existem no ambiente de destino;
- criar ou substituir essas estruturas quando necessário;
- revisar tipos de dados e regras associadas;
- homologar antes de implantar em produção.

## Cuidados antes da implantação

Antes de executar qualquer script:

1. leia a documentação específica do módulo;
2. revise códigos de empresa, centro de resultado, TOP, natureza, usuário e demais parâmetros fixos;
3. confirme campos e tabelas adicionais;
4. valide dependências com outros objetos;
5. teste em homologação;
6. somente depois faça a implantação em produção.

## Importante

Este repositório contém customizações específicas de ambiente e não representa código oficial da Sankhya.

Regras de negócio, estruturas adicionais, códigos internos e fluxos podem variar entre empresas.

## Tecnologias

- Sankhya ERP
- Oracle Database
- PL/SQL
