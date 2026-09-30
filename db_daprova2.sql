CREATE DATABASE IF NOT EXISTS db_prova;
USE db_prova;


SELECT * FROM db_prova.garantia_safra;


#1----------------------------------------------------------------------------------------------------------------------------------------------------------------
#1.1 CTE para ler os estados exatamente na ordem desejada
WITH cte_base_filtrada AS (
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'RN'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'MA'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'CE'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'PE'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'AL'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'BA'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'MG'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'PB'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'PI'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'SE'
    UNION ALL
    SELECT ano_referencia, sigla_uf, id_municipio, nis_favorecido, valor_parcela FROM db_prova.garantia_safra WHERE ano_referencia >= 2020 AND sigla_uf = 'AM'
),

#1.2 CTE para somar os valores e contar o total de registros por UF/Ano
cte_movimentacao_financeira AS (
    SELECT 
        ano_referencia,
        sigla_uf,
        SUM(valor_parcela) AS valor_total,
        COUNT(valor_parcela) AS qtd_parcelas
    FROM cte_base_filtrada
    GROUP BY ano_referencia, sigla_uf
),

#1.3 CTE para contagem de beneficiários distintos e de municípios atendidos por UF/Ano
cte_cobertura AS (
    SELECT 
        ano_referencia,
        sigla_uf,
        COUNT(DISTINCT nis_favorecido) AS beneficiarios_unicos,
        COUNT(DISTINCT id_municipio) AS municipios_atendidos
    FROM cte_base_filtrada
    GROUP BY ano_referencia, sigla_uf
),

#1.4 calcular o valor médio por parcela/ticket e o maior valor registrado
cte_estatisticas AS (
    SELECT 
        ano_referencia,
        sigla_uf,
        ROUND(AVG(valor_parcela), 2) AS ticket_medio,
        MAX(valor_parcela) AS maior_valor
    FROM cte_base_filtrada
    GROUP BY ano_referencia, sigla_uf
),

#1.5 classificar pagamentos em faixas alta, média ou baixa
cte_faixas_pagamento AS (
    SELECT 
        ano_referencia,
        sigla_uf,
        SUM(CASE WHEN valor_parcela <= 200 THEN 1 ELSE 0 END) AS qtd_faixa_baixa,
        SUM(CASE WHEN valor_parcela > 200 AND valor_parcela <= 700 THEN 1 ELSE 0 END) AS qtd_faixa_media,
        SUM(CASE WHEN valor_parcela > 700 THEN 1 ELSE 0 END) AS qtd_faixa_alta
    FROM cte_base_filtrada
    GROUP BY ano_referencia, sigla_uf
)

# 1.6 União de todas as CTEs anteriores em um único relatório consolidado 
SELECT 
    f.sigla_uf AS uf,
    f.ano_referencia AS ano,
    f.valor_total,
    f.qtd_parcelas,
    c.beneficiarios_unicos,
    c.municipios_atendidos,
    e.ticket_medio,
    e.maior_valor,
    f_faixa.qtd_faixa_baixa,
    f_faixa.qtd_faixa_media,
    f_faixa.qtd_faixa_alta,
    CASE 
        WHEN e.ticket_medio <= 250 THEN 'Baixo'
        WHEN e.ticket_medio > 250 AND e.ticket_medio <= 600 THEN 'Médio'
        ELSE 'Alto'
    END AS classificacao_ticket_medio
FROM cte_movimentacao_financeira f
INNER JOIN cte_cobertura c 
    ON f.ano_referencia = c.ano_referencia AND f.sigla_uf = c.sigla_uf
INNER JOIN cte_estatisticas e 
    ON f.ano_referencia = e.ano_referencia AND f.sigla_uf = e.sigla_uf
INNER JOIN cte_faixas_pagamento f_faixa 
    ON f.ano_referencia = f_faixa.ano_referencia AND f.sigla_uf = f_faixa.sigla_uf;

#2-----------------------------------------------------------------------------------------------------------------------------------
# 2.1 CTE que filtra os registros do ano de 2020 
WITH cte_base_2020 AS (
    SELECT 
        ano_referencia,
        sigla_uf,
        id_municipio,
        nis_favorecido,
        valor_parcela
    FROM db_prova.garantia_safra
    WHERE ano_referencia = 2020
),

# 2.2 valor total recebido por cada UF em 2020 e a quantidade de parcelas pagas
cte_consolidado_financeiro AS (
    SELECT 
        sigla_uf AS uf,
        SUM(valor_parcela) AS valor_total,
        COUNT(valor_parcela) AS qtd_parcelas
    FROM cte_base_2020
    GROUP BY sigla_uf
),

# 2.3 CTE que traz o número de beneficiários distintos por UF em 2020
cte_beneficiarios AS (
    SELECT 
        sigla_uf AS uf,
        COUNT(DISTINCT nis_favorecido) AS beneficiarios_distintos
    FROM cte_base_2020
    GROUP BY sigla_uf
),

# 2.4 quantos municipios diferentes receberam parcelas em cada UF
cte_municipios AS (
    SELECT 
        sigla_uf AS uf,
        COUNT(DISTINCT id_municipio) AS municipios_distintos
    FROM cte_base_2020
    GROUP BY sigla_uf
),

# 2.5 valor total pago pelo programa no Brasil em 2020
cte_total_brasil AS (
    SELECT 
        SUM(valor_parcela) AS total_brasil
    FROM cte_base_2020
),

# 2.6 classificar cada UF em Alto valor, Médio e baixo
cte_faixa_valor AS (
    SELECT 
        uf,
        CASE 
            WHEN valor_total > 20000 THEN 'alto valor'
            WHEN valor_total >= 10000 AND valor_total <= 20000 THEN 'médio valor'
            ELSE 'baixo valor'
        END AS faixa_valor
    FROM cte_consolidado_financeiro
),

# 2.7 cte que seleciona as cinco ufs com maiores valores totais
cte_top5_ufs AS (
    SELECT 
        uf,
        valor_total
    FROM cte_consolidado_financeiro
    ORDER BY valor_total DESC
    LIMIT 5
)

# 2.8 união de todas as ctes e relatório final
SELECT 
    t5.uf,
    f.valor_total,
    f.qtd_parcelas,
    b.beneficiarios_distintos AS beneficiarios,
    m.municipios_distintos AS municipios,
    ROUND((f.valor_total / br.total_brasil) * 100, 2) AS participacao_percentual,
    fx.faixa_valor,
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY f.valor_total DESC) = 1 THEN 'lider_Br'
        ELSE 'top_5'
    END AS grupo_destaque
FROM cte_top5_ufs t5
INNER JOIN cte_consolidado_financeiro f ON t5.uf = f.uf
INNER JOIN cte_beneficiarios b ON t5.uf = b.uf
INNER JOIN cte_municipios m ON t5.uf = m.uf
INNER JOIN cte_faixa_valor fx ON t5.uf = fx.uf
CROSS JOIN cte_total_brasil br
ORDER BY f.valor_total DESC;

#3-------------------------------------------------------------------------------------------------------------
WITH 
#3.1 ctes seleciona todos os dados a partir de 2020
cte_base AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_referencia,
        nis_favorecido,
        nome_favorecido, -- Adicionado para atender o relatório final
        valor_parcela
    FROM db_prova.garantia_safra
    WHERE ano_referencia >= 2020
),

#3.2 cte que calcula para cada beneficiario o valor total recebido a média por parcela e a quantidade de parcelas
cte_beneficiario AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_referencia,
        nis_favorecido,
        nome_favorecido, 
        SUM(valor_parcela) AS valor_total_beneficiario,
        AVG(valor_parcela) AS media_por_parcela,
        COUNT(valor_parcela) AS qtd_parcelas
    FROM cte_base
    GROUP BY sigla_uf, id_municipio, ano_referencia, nis_favorecido, nome_favorecido
),

#3.3 quanto o municipio inteiro recebeu em cada ano
cte_municipio AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_referencia,
        SUM(valor_parcela) AS total_municipio
    FROM cte_base
    GROUP BY sigla_uf, id_municipio, ano_referencia
),

#3.4 cte que identifica o maior valor total recebido por um único beneficiario em cada municipio e ano
cte_maior_beneficiario AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_referencia,
        MAX(valor_total_beneficiario) AS maior_total_individual
    FROM cte_beneficiario
    GROUP BY sigla_uf, id_municipio, ano_referencia
),

#3.5 cte que classifica cada beneficiario em alto, médio ou baixo
cte_classificacao AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_referencia,
        nis_favorecido,
        CASE 
            WHEN valor_total_beneficiario >= 800 THEN 'ALTO'
            WHEN valor_total_beneficiario >= 500 AND valor_total_beneficiario < 800 THEN 'MÉDIO'
            ELSE 'BAIXO'
        END AS faixa_valor
    FROM cte_beneficiario
)

#3.6 união de todas as ctes e relatório final
SELECT 
    b.sigla_uf AS uf,
    b.id_municipio AS municipio,
    b.ano_referencia AS ano,
    b.nis_favorecido AS nis,
    b.nome_favorecido AS nome,
    b.valor_total_beneficiario AS total_recebido,
    ROUND(b.media_por_parcela, 2) AS media_por_parcela,
    b.qtd_parcelas,
    m.total_municipio,
    ROUND((b.valor_total_beneficiario / m.total_municipio) * 100, 2) AS participacao_percentual,
    mb.maior_total_individual,
    c.faixa_valor,
    CASE 
        WHEN b.valor_total_beneficiario = mb.maior_total_individual THEN 'DESTAQUE_MUNICIPAL'
        ELSE 'OUTROS'
    END AS grupo_destaque
FROM cte_beneficiario b
JOIN cte_municipio m 
    ON b.sigla_uf = m.sigla_uf AND b.id_municipio = m.id_municipio AND b.ano_referencia = m.ano_referencia
JOIN cte_maior_beneficiario mb 
    ON b.sigla_uf = mb.sigla_uf AND b.id_municipio = mb.id_municipio AND b.ano_referencia = mb.ano_referencia
JOIN cte_classificacao c 
    ON b.sigla_uf = c.sigla_uf AND b.id_municipio = c.id_municipio AND b.ano_referencia = c.ano_referencia AND b.nis_favorecido = c.nis_favorecido;
