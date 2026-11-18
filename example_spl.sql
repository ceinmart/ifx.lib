-- Projeto: ifxlib
-- Arquivo: example_spl.sql
-- Versao: 1.4.8
-- Criado em: 2026-11-18 09:03:38 -0300
-- Criado por: ChatGPT - OpenAI
-- Exemplo autocontido: cria, executa e remove a procedure de demonstracao.

CREATE OR REPLACE PROCEDURE exemplo_uso_udr()
    RETURNING VARCHAR(40) AS etapa,
              INTEGER AS contador,
              DATETIME YEAR TO FRACTION(3) AS data_hora,
              INTEGER AS intervalo_cpu;

    DEFINE v_etapa VARCHAR(40);
    DEFINE v_contador INTEGER;
    DEFINE v_agora DATETIME YEAR TO FRACTION(3);
    DEFINE v_intervalo INTEGER;

    LET v_contador = 0;

    -- A configuracao fica nesta sessao e o setter zera o contador interno.
    LET v_intervalo = 1000;
    EXECUTE PROCEDURE sp_cpu(v_intervalo);

    LET v_etapa = 'inicio';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    WHILE v_contador < 100000
        LET v_contador = v_contador + 1;

        -- Trabalho real da procedure entra aqui.

        -- O contador do intervalo fica dentro da UDR C.
        EXECUTE PROCEDURE sp_cpu();
    END WHILE;

    LET v_etapa = 'fim do intervalo 1000';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    -- Muda o intervalo para as chamadas seguintes da mesma sessao.
    LET v_intervalo = 10000;
    EXECUTE PROCEDURE sp_cpu(v_intervalo);

    LET v_etapa = 'intervalo alterado para 10000';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    WHILE v_contador < 200000
        LET v_contador = v_contador + 1;
        EXECUTE PROCEDURE sp_cpu();
    END WHILE;

    LET v_etapa = 'fim do intervalo 10000';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    -- Zero faz yield em todas as chamadas.
    LET v_intervalo = 0;
    EXECUTE PROCEDURE sp_cpu(0);

    LET v_etapa = 'yield em todas as chamadas';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    -- -1 desativa o yield ate uma nova configuracao da mesma sessao.
    LET v_intervalo = -1;
    EXECUTE PROCEDURE sp_cpu(-1);

    LET v_etapa = 'yield desativado';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;

    -- Restaura o comportamento default antes de encerrar o exemplo.
    LET v_intervalo = 0;
    EXECUTE PROCEDURE sp_cpu(0);

    LET v_etapa = 'configuracao restaurada';
    LET v_agora = sp_current2();
    RETURN v_etapa, v_contador, v_agora, v_intervalo WITH RESUME;
END PROCEDURE;

-- Exibe as linhas produzidas pelos RETURN WITH RESUME.
EXECUTE PROCEDURE exemplo_uso_udr();

-- Remove a procedure de demonstracao para nao deixar objetos no banco.
DROP PROCEDURE IF EXISTS exemplo_uso_udr;
