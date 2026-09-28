CREATE OR REPLACE PROCEDURE STP_LIBERACAO_CONT_MB (
    P_NUNOTA    IN NUMBER,
    P_SUCESSO   OUT VARCHAR,
    P_MENSAGEM  OUT VARCHAR2,
    P_CODUSULIB OUT NUMBER
) AS
    V_STATUS    VARCHAR2(1);
    V_CODEMP    NUMBER;
    V_CODCENCUS NUMBER;
BEGIN

    ----------------------------------------------------------------
    -- Busca status da nota, empresa e centro de resultado
    ----------------------------------------------------------------
    SELECT STATUSNOTA,
           CODEMP,
           CODCENCUS
      INTO V_STATUS,
           V_CODEMP,
           V_CODCENCUS
      FROM TGFCAB
     WHERE NUNOTA = P_NUNOTA;

    ----------------------------------------------------------------
    -- EXCEÇÃO:
    -- A procedure não exige liberação SOMENTE quando as duas
    -- condições forem atendidas ao mesmo tempo:
    --   Empresa             = 31
    --   Centro de Resultado = 1040112
    ----------------------------------------------------------------
    IF V_CODEMP = 31
       AND V_CODCENCUS = 1040112 THEN

        P_SUCESSO := 'S';
        P_MENSAGEM := NULL;
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- Regra normal
    ----------------------------------------------------------------
    IF V_STATUS = 'L' THEN
        P_SUCESSO := 'S';
        P_MENSAGEM := NULL;
        RETURN;
    END IF;

    ----------------------------------------------------------------
    -- Caso contrário, exige liberação
    ----------------------------------------------------------------
    P_SUCESSO := 'N';
    P_MENSAGEM := 'FALTA LIBERAÇÃO';

END STP_LIBERACAO_CONT_MB;
/
