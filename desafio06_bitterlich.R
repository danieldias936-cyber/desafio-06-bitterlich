# =============================================================================
# DESAFIO 06 — Processamento de Inventário por Amostragem de Bitterlich
# Mestrado em Ciências Florestais — ICA/UFMG — Mensuração Florestal
# -----------------------------------------------------------------------------
# Uso:  Rscript desafio06_bitterlich.R bitterlich_talhao20.xlsx [pasta_saida]
# Entradas : planilha com as abas Info_Talhao, Pontos e Arvores
#            + coeficientes da relação hipsométrica (Desafio 02, Talhão 8)
#            + coeficientes da equação de volume (Desafio 04, Talhão 8)
# Saídas   : arvores_processadas.csv, resumo_por_ponto.csv, resumo_inventario.csv
#            (+ resumo_area_basal.csv, verificação sem depender de H e V)
# =============================================================================

suppressPackageStartupMessages(library(readxl))

# -----------------------------------------------------------------------------
# 0. PARÂMETROS DOS MODELOS AJUSTADOS NO TALHÃO 8  >>> PREENCHER <<<
# -----------------------------------------------------------------------------
# Relação hipsométrica (Desafio 02). Escolha o modelo ajustado e informe b0, b1.
#   "chapman"    : H     = b0 * (1 - exp(-b1 * DAP))^b2   <- selecionado no Desafio 02
#   "curtis"     : ln(H) = b0 + b1 * (1/DAP)
#   "stoffels"   : ln(H) = b0 + b1 * ln(DAP)
#   "henricksen" : H     = b0 + b1 * ln(DAP)
#   "linear"     : H     = b0 + b1 * DAP
# Fonte: repositório desafio_altura (Talhão 8; n = 109 árvores com HT medida;
#        DAP de calibração 9,6–21,9 cm). Ajuste por mínimos quadrados não lineares.
MODELO_HIPSO <- "chapman"
COEF_HIPSO   <- c(b0 = 32.7393585679, b1 = 0.2226784703, b2 = 5.3325132909)

# Equação de volume de dupla entrada (Desafio 04).
#   "spurr"           : V     = b0 + b1*(DAP^2 * H)       <- selecionada no Desafio 04
#   "schumacher_hall" : ln(V) = b0 + b1*ln(DAP) + b2*ln(H)
#   "spurr_log"       : ln(V) = b0 + b1*ln(DAP^2 * H)
# Fonte: repositório desafio-04-volume-reduzido-e-tabela (equacoes_volume.csv;
#        36 árvores cubadas por Smalian, DAP 5,6–18,7 cm). Spurr teve maior R² em
#        LOOCV (0,9874; RMSE 4,43%) entre as equações de dupla entrada.
# Alternativa (sensibilidade): Schumacher-Hall b0 = -10.4128627640244,
#        b1 = 1.65586225171414, b2 = 1.35238842912164, Meyer = 1.0012372789852
MODELO_VOL <- "spurr"
COEF_VOL   <- c(b0 = 0.00409597022500541, b1 = 3.62975905184689e-05, b2 = NA_real_)

# Correção de Meyer para modelos logarítmicos (exp(QME/2)). Use 1 se não aplicada
# no Desafio 02/04 — o importante é manter a mesma convenção dos desafios anteriores.
FATOR_MEYER_H <- 1
FATOR_MEYER_V <- 1

NIVEL_CONF <- 0.95

# -----------------------------------------------------------------------------
# 1. LEITURA DOS DADOS
# -----------------------------------------------------------------------------
args    <- commandArgs(trailingOnly = TRUE)
arquivo <- if (length(args) >= 1) args[1] else "bitterlich_talhao20.xlsx"
saida   <- if (length(args) >= 2) args[2] else "."
dir.create(saida, showWarnings = FALSE, recursive = TRUE)

info    <- read_excel(arquivo, sheet = "Info_Talhao")
pontos  <- read_excel(arquivo, sheet = "Pontos")
arvores <- as.data.frame(read_excel(arquivo, sheet = "Arvores"))

# coluna 1 = nome da variável, coluna 2 = valor (por posição, evita problemas de acentuação)
pega_info <- function(padrao) as.numeric(info[[2]][grepl(padrao, info[[1]])][1])
AREA_HA <- pega_info("rea total")
FAB     <- pega_info("FAB")
N_PTS   <- pega_info("mero de pontos")
TALHAO  <- pega_info("^Talh")

cat(sprintf("Talhão %g | Área = %g ha | FAB = %g m²/ha | pontos = %g | árvores contadas = %d\n",
            TALHAO, AREA_HA, FAB, N_PTS, nrow(arvores)))
stopifnot(length(unique(arvores$Ponto)) == N_PTS)

# -----------------------------------------------------------------------------
# FUNÇÃO 1 — Área seccional (m²) e nº de árvores/ha representado (fator de expansão)
#   g_i = pi/40000 * DAP_i²      (DAP em cm -> g em m²)
#   N_i = FAB / g_i              (árv/ha que cada árvore "contada" representa)
# Inclui a checagem do raio limite: R_i (m) = DAP_i(cm) / (2*sqrt(FAB)).
# Árvore com distância > R_i não deveria ter sido contada.
# -----------------------------------------------------------------------------
calc_expansao <- function(dap_cm, fab) {
  g  <- pi / 40000 * dap_cm^2
  data.frame(g_m2 = g, n_arvores_ha = fab / g,
             raio_limite_m = dap_cm / (2 * sqrt(fab)))
}

# -----------------------------------------------------------------------------
# FUNÇÃO 2 — Altura estimada e volume individual (modelos do Talhão 8)
# -----------------------------------------------------------------------------
estima_altura <- function(dap, modelo = MODELO_HIPSO, b = COEF_HIPSO, meyer = FATOR_MEYER_H) {
  switch(modelo,
    chapman    = b["b0"] * (1 - exp(-b["b1"] * dap))^b["b2"],
    curtis     = exp(b["b0"] + b["b1"] / dap) * meyer,
    stoffels   = exp(b["b0"] + b["b1"] * log(dap)) * meyer,
    henricksen = b["b0"] + b["b1"] * log(dap),
    linear     = b["b0"] + b["b1"] * dap,
    stop("Modelo hipsométrico desconhecido"))
}

estima_volume <- function(dap, h, modelo = MODELO_VOL, b = COEF_VOL, meyer = FATOR_MEYER_V) {
  switch(modelo,
    schumacher_hall = exp(b["b0"] + b["b1"] * log(dap) + b["b2"] * log(h)) * meyer,
    spurr           = b["b0"] + b["b1"] * dap^2 * h,
    spurr_log       = exp(b["b0"] + b["b1"] * log(dap^2 * h)) * meyer,
    stop("Modelo volumétrico desconhecido"))
}

# -----------------------------------------------------------------------------
# FUNÇÃO 3 — Agregação por ponto
#   Volume_ha(ponto) = Σ N_i * V_i     |  G_ha(ponto) = Σ N_i * g_i = n_contadas * FAB
# -----------------------------------------------------------------------------
resumo_ponto <- function(df) {
  do.call(rbind, lapply(split(df, df$ponto), function(p) data.frame(
    ponto                      = p$ponto[1],
    n_contadas                 = nrow(p),
    dap_medio_cm               = mean(p$dap_cm),
    altura_media_m             = mean(p$altura_estimada_m),
    volume_individual_medio_m3 = mean(p$volume_individual_m3),
    n_arvores_ha               = sum(p$n_arvores_ha),
    area_basal_ha_m2           = sum(p$n_arvores_ha * p$g_m2),
    volume_ha_m3               = sum(p$n_arvores_ha * p$volume_individual_m3))))
}

# -----------------------------------------------------------------------------
# FUNÇÃO 4 — Processamento por Amostragem Aleatória Simples (AAS)
#   Os n pontos são as unidades amostrais; população tratada como infinita
#   (sem correção de população finita — no Bitterlich a unidade é um ponto,
#   não uma parcela de área fixa, logo N não é definido).
# -----------------------------------------------------------------------------
processa_aas <- function(y, area_ha, conf = NIVEL_CONF) {
  n   <- length(y)
  m   <- mean(y)
  s2  <- var(y)                       # divisor n-1
  s   <- sqrt(s2)
  sx  <- s / sqrt(n)
  t   <- qt(1 - (1 - conf) / 2, df = n - 1)
  ea  <- t * sx
  data.frame(
    n_pontos = n, t_student = t,
    volume_medio_ha_m3 = m, variancia = s2, desvio_padrao = s,
    cv_pct = 100 * s / m,
    erro_padrao_media = sx, erro_absoluto = ea, erro_relativo_pct = 100 * ea / m,
    ic_inferior_ha = m - ea, ic_superior_ha = m + ea,
    volume_total_talhao_m3 = m * area_ha,
    ic_inferior_total = (m - ea) * area_ha, ic_superior_total = (m + ea) * area_ha)
}

# -----------------------------------------------------------------------------
# 2. PROCESSAMENTO
# -----------------------------------------------------------------------------
arv <- data.frame(ponto = arvores$Ponto, arvore = arvores$Arvore,
                  dap_cm = arvores$DAP_cm, distancia_m = arvores$Distancia_m)
arv <- cbind(arv, calc_expansao(arv$dap_cm, FAB))

fora <- sum(arv$distancia_m > arv$raio_limite_m)
cat(sprintf("Checagem do raio limite: %d árvore(s) além do raio limite.\n", fora))

# Verificação independente dos modelos: área basal e nº de árvores por hectare
ver <- aggregate(cbind(n_arvores_ha, g_ha = n_arvores_ha * g_m2) ~ ponto, data = arv, FUN = sum)
inv_G <- processa_aas(ver$g_ha, AREA_HA);        inv_G$variavel <- "area_basal_m2_ha"
inv_N <- processa_aas(ver$n_arvores_ha, AREA_HA); inv_N$variavel <- "n_arvores_ha"
write.csv(rbind(inv_G, inv_N), file.path(saida, "resumo_area_basal.csv"), row.names = FALSE)
cat(sprintf("G/ha = %.2f m²/ha (ER = %.2f%%) | N/ha = %.0f árv/ha (ER = %.2f%%)\n",
            inv_G$volume_medio_ha_m3, inv_G$erro_relativo_pct,
            inv_N$volume_medio_ha_m3, inv_N$erro_relativo_pct))

if (any(is.na(COEF_HIPSO[c("b0","b1")])) || any(is.na(COEF_VOL[c("b0","b1")]))) {
  stop("Preencha COEF_HIPSO e COEF_VOL (Desafios 02 e 04) no bloco 0 para estimar H e V.")
}

arv$altura_estimada_m    <- as.numeric(estima_altura(arv$dap_cm))
arv$volume_individual_m3 <- as.numeric(estima_volume(arv$dap_cm, arv$altura_estimada_m))

# Extrapolação: árvores fora da amplitude de DAP usada na calibração do Talhão 8
FAIXA_DAP_HIPSO <- c(9.65, 21.95); FAIXA_DAP_CUB <- c(5.64, 18.74)
cat(sprintf("Árvores fora da faixa de DAP da relação hipsométrica (%.1f–%.1f cm): %d de %d\n",
            FAIXA_DAP_HIPSO[1], FAIXA_DAP_HIPSO[2],
            sum(arv$dap_cm < FAIXA_DAP_HIPSO[1] | arv$dap_cm > FAIXA_DAP_HIPSO[2]), nrow(arv)))
cat(sprintf("Árvores acima do maior DAP cubado (%.1f cm): %d de %d\n",
            FAIXA_DAP_CUB[2], sum(arv$dap_cm > FAIXA_DAP_CUB[2]), nrow(arv)))

por_ponto <- resumo_ponto(arv)
inv       <- processa_aas(por_ponto$volume_ha_m3, AREA_HA)

# -----------------------------------------------------------------------------
# 3. SAÍDAS
# -----------------------------------------------------------------------------
write.csv(arv[, c("ponto", "arvore", "dap_cm", "altura_estimada_m",
                  "volume_individual_m3", "n_arvores_ha")],
          file.path(saida, "arvores_processadas.csv"), row.names = FALSE)
write.csv(por_ponto[, c("ponto", "dap_medio_cm", "altura_media_m",
                        "volume_individual_medio_m3", "volume_ha_m3")],
          file.path(saida, "resumo_por_ponto.csv"), row.names = FALSE)
write.csv(inv[, c("volume_medio_ha_m3", "variancia", "desvio_padrao", "erro_padrao_media",
                  "erro_absoluto", "erro_relativo_pct", "ic_inferior_ha", "ic_superior_ha",
                  "volume_total_talhao_m3", "ic_inferior_total", "ic_superior_total")],
          file.path(saida, "resumo_inventario.csv"), row.names = FALSE)

print(t(round(inv, 4)))
