CREATE OR REPLACE PROCEDURE STP_LIBERACAO_ELECTRA_MB (
    P_NUNOTA    IN NUMBER,
    P_SUCESSO   OUT VARCHAR,
    P_MENSAGEM  OUT VARCHAR2,
    P_CODUSULIB OUT NUMBER
) AS
    V_CODEMP    NUMBER;
    V_CODCENCUS NUMBER;
BEGIN

    ----------------------------------------------------------------
    -- Busca empresa e centro de resultado da nota
    ----------------------------------------------------------------
    SELECT CODEMP,
           CODCENCUS
      INTO V_CODEMP,
           V_CODCENCUS
      FROM TGFCAB
     WHERE NUNOTA = P_NUNOTA;

    ----------------------------------------------------------------
    -- REGRA ELECTRA
    --
    -- Exige liberação somente quando as duas condições forem
    -- atendidas simultaneamente:
    --   Empresa             = 31
    --   Centro de Resultado = 1040112
    --
    -- O usuário liberador é definido na tela da Regra de Negócio
    -- do Sankhya, e não nesta procedure.
    ----------------------------------------------------------------
    IF V_CODEMP = 31
       AND V_CODCENCUS = 1040112 THEN

        P_SUCESSO  := 'N';
        P_MENSAGEM := 'FALTA LIBERAÇÃO - ELECTRA';
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- Fora da combinação Empresa 31 + CR 1040112,
    -- esta regra não exige liberação.
    ----------------------------------------------------------------
    P_SUCESSO  := 'S';
    P_MENSAGEM := NULL;

END STP_LIBERACAO_ELECTRA_MB;
/
