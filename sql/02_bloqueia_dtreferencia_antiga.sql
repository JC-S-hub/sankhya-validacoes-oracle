CREATE OR REPLACE TRIGGER TRG_BLOQUEIA_DTREFERENCIA_ANTIGA
BEFORE INSERT OR UPDATE ON TGFFIN
FOR EACH ROW
DECLARE
    ---------------------------------------------------------------------------
    -- CONFIGURAÇÃO
    ---------------------------------------------------------------------------
    c_nome_trigger CONSTANT VARCHAR2(100) :=
        'TRG_BLOQUEIA_DTREFERENCIA_ANTIGA';

    ---------------------------------------------------------------------------
    -- VARIÁVEIS
    ---------------------------------------------------------------------------
    v_status_trigger         NUMBER := 0;
    v_status_nota            TGFCAB.STATUSNOTA%TYPE;
    v_dtreferencia_alterada  BOOLEAN := FALSE;
    v_inicio_mes_referencia  DATE;
    v_inicio_mes_anterior    DATE;
BEGIN
    ---------------------------------------------------------------------------
    -- 1. VERIFICA SE A TRIGGER ESTÁ ATIVA
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
    -- 2. EXCEÇÕES INICIAIS
    ---------------------------------------------------------------------------
    IF :NEW.RECDESP = 1 THEN
        RETURN;
    END IF;

    -- Preserva a referência gerada automaticamente por remessa na inclusão.
    IF INSERTING AND :NEW.NUMREMESSA IS NOT NULL THEN
        RETURN;
    END IF;

    ---------------------------------------------------------------------------
    -- 3. IDENTIFICA ALTERAÇÃO EFETIVA DA DTREFERENCIA
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
    -- 4. TRATAMENTO DOS LANÇAMENTOS ORIGINADOS DE NOTA
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
    ELSE
        -- Para lançamento direto, integração ou outra origem, só revalida
        -- em UPDATE quando DTREFERENCIA tiver sido alterada.
        IF UPDATING AND NOT v_dtreferencia_alterada THEN
            RETURN;
        END IF;
    END IF;

    ---------------------------------------------------------------------------
    -- 5. A OBRIGATORIEDADE É RESPONSABILIDADE DA PRIMEIRA TRIGGER
    ---------------------------------------------------------------------------
    IF :NEW.DTREFERENCIA IS NULL THEN
        RETURN;
    END IF;

    ---------------------------------------------------------------------------
    -- 6. RENEGOCIAÇÃO PODE PRESERVAR REFERÊNCIA ANTIGA NA INCLUSÃO
    ---------------------------------------------------------------------------
    IF INSERTING AND :NEW.NURENEG IS NOT NULL THEN
        RETURN;
    END IF;

    ---------------------------------------------------------------------------
    -- 7. CALCULA E VALIDA O LIMITE TEMPORAL
    ---------------------------------------------------------------------------
    v_inicio_mes_referencia := TRUNC(:NEW.DTREFERENCIA, 'MM');
    v_inicio_mes_anterior   := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1);

    IF v_inicio_mes_referencia < v_inicio_mes_anterior THEN
        IF INSERTING THEN
            RAISE_APPLICATION_ERROR(
                -20021,
                'Só é permitido informar o período de referência do mês anterior, do mês atual ou de meses futuros.'
            );
        ELSE
            RAISE_APPLICATION_ERROR(
                -20022,
                'Alteração não permitida: o período de referência não pode ser anterior ao mês anterior.'
            );
        END IF;
    END IF;
END;
/
