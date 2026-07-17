CREATE OR REPLACE TRIGGER TRG_VALIDA_DTREFERENCIA
BEFORE INSERT OR UPDATE ON TGFFIN
FOR EACH ROW
DECLARE
    ---------------------------------------------------------------------------
    -- CONFIGURAÇÃO
    ---------------------------------------------------------------------------
    c_nome_trigger CONSTANT VARCHAR2(100) := 'TRG_VALIDA_DTREFERENCIA';

    ---------------------------------------------------------------------------
    -- VARIÁVEIS
    ---------------------------------------------------------------------------
    v_status_trigger         NUMBER := 0;
    v_status_nota            TGFCAB.STATUSNOTA%TYPE;
    v_dtreferencia_alterada  BOOLEAN := FALSE;
BEGIN
    ---------------------------------------------------------------------------
    -- 1. VERIFICA SE A TRIGGER ESTÁ ATIVA
    --
    -- O SQL dinâmico permite a compilação mesmo quando a tabela customizada
    -- AD_CTRIGGER não existe ou não está acessível no ambiente.
    ---------------------------------------------------------------------------
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT NVL(MAX(STATUSTGG), 0)
               FROM AD_CTRIGGER
              WHERE NOMETGG = :1'
            INTO v_status_trigger
            USING c_nome_trigger;
    EXCEPTION
        WHEN OTHERS THEN
            v_status_trigger := 0;
    END;

    IF NVL(v_status_trigger, 0) <> 1 THEN
        RETURN;
    END IF;

    ---------------------------------------------------------------------------
    -- 2. IDENTIFICA ALTERAÇÃO EFETIVA DA DTREFERENCIA
    ---------------------------------------------------------------------------
    IF UPDATING THEN
        v_dtreferencia_alterada :=
               (:OLD.DTREFERENCIA IS NULL AND :NEW.DTREFERENCIA IS NOT NULL)
            OR (:OLD.DTREFERENCIA IS NOT NULL AND :NEW.DTREFERENCIA IS NULL)
            OR (:OLD.DTREFERENCIA IS NOT NULL
                AND :NEW.DTREFERENCIA IS NOT NULL
                AND :OLD.DTREFERENCIA <> :NEW.DTREFERENCIA);
    END IF;

    ---------------------------------------------------------------------------
    -- 3. TRATAMENTO DOS LANÇAMENTOS ORIGINADOS DE NOTA
    ---------------------------------------------------------------------------
    IF :NEW.ORIGEM = 'E' THEN
        IF :NEW.NUNOTA IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20023,
                'Não foi possível validar o período de referência: lançamento de origem E sem nota vinculada.'
            );
        END IF;

        BEGIN
            SELECT CAB.STATUSNOTA
              INTO v_status_nota
              FROM TGFCAB CAB
             WHERE CAB.NUNOTA = :NEW.NUNOTA;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20023,
                    'Não foi possível validar o período de referência: a nota vinculada não foi encontrada na TGFCAB.'
                );
            WHEN TOO_MANY_ROWS THEN
                RAISE_APPLICATION_ERROR(
                    -20024,
                    'Não foi possível validar o período de referência: foi encontrada mais de uma nota para o mesmo NUNOTA.'
                );
        END;

        IF v_status_nota = 'L' THEN
            IF INSERTING THEN
                RETURN;
            END IF;

            IF UPDATING AND NOT v_dtreferencia_alterada THEN
                RETURN;
            END IF;
        END IF;
    END IF;

    ---------------------------------------------------------------------------
    -- 4. VALIDAÇÃO DE PREENCHIMENTO
    --
    -- CONFIGURAÇÃO DO AMBIENTE:
    -- revise os códigos de TOP e natureza antes da instalação.
    ---------------------------------------------------------------------------
    IF :NEW.CODTIPOPER NOT IN (9996, 1501, 1490, 1502, 1503, 1506)
       AND :NEW.RECDESP <> 1
       AND :NEW.CODNAT NOT IN (
           '11030100',
           '11020100',
           '11010100',
           '11030200',
           '11020200',
           '11010200',
           '10020200'
       )
       AND :NEW.PROVISAO = 'N'
       AND :NEW.ORIGEM <> 'P'
       AND :NEW.DTREFERENCIA IS NULL
    THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'O campo Período de referência precisa ser preenchido.'
        );
    END IF;
END;
/
