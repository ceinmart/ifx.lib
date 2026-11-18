-- Projeto: ifxlib
-- Arquivo: example_spl.sql
-- Versao: 1.4.0
-- Criado em: 2026-11-12 10:45:57 -0300
-- Criado por: ChatGPT - OpenAI
-- Exemplo de uso; adapte o processamento para sua rotina real.

CREATE PROCEDURE exemplo_uso_udr()
    DEFINE v_contador INTEGER;
    DEFINE v_agora DATETIME YEAR TO FRACTION(3);

    LET v_contador = 0;

    -- A configuracao fica nesta sessao e o setter zera o contador interno.
    EXECUTE PROCEDURE sp_cpu(1000);

    WHILE v_contador < 100000
        LET v_contador = v_contador + 1;

        -- Trabalho real da procedure entra aqui.

        -- O MOD e o contador agora ficam dentro da UDR C.
        EXECUTE PROCEDURE sp_cpu();

        IF MOD(v_contador, 1000) = 0 THEN
            LET v_agora = sp_current2();
        END IF;
    END WHILE;

    -- Muda o intervalo para as chamadas seguintes da mesma sessao.
    EXECUTE PROCEDURE sp_cpu(10000);

    WHILE v_contador < 200000
        LET v_contador = v_contador + 1;
        EXECUTE PROCEDURE sp_cpu();
    END WHILE;

    -- Zero restaura o modo de yield em todas as chamadas.
    EXECUTE PROCEDURE sp_cpu(0);

    -- -1 desativa o yield ate uma nova configuracao da mesma sessao.
    EXECUTE PROCEDURE sp_cpu(-1);
END PROCEDURE;
