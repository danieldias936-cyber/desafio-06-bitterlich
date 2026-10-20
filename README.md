# Desafio 06 — Inventário por Amostragem de Bitterlich (Talhão 20)

Processamento em R do inventário do Talhão 20 (25 ha; FAB = 3 m²/ha; 25 pontos em grade de 100 × 100 m; 228 árvores contadas), com estimativa do volume por hectare, do erro de amostragem e do volume total do talhão.

## Execução

```bash
Rscript desafio06_bitterlich.R bitterlich_talhao20.xlsx out_t20
```

Pacote necessário: `readxl`. O script é genérico. Ele lê a área, o FAB e o número de pontos da aba `Info_Talhao`, então também processa outros talhões no mesmo formato.

## Fórmulas

| Etapa | Fórmula |
|---|---|
| Área seccional | gᵢ = π/40000 · DAPᵢ² (m², com DAP em cm) |
| Árvores/ha representadas | Nᵢ = FAB / gᵢ |
| Raio limite (checagem) | Rᵢ = DAPᵢ / (2√FAB) (m). Nenhuma das 228 árvores excedeu esse raio |
| Altura (Desafio 02, Chapman-Richards) | H = 32,7394 · (1 − e^(−0,222678·DAP))^5,332513 |
| Volume (Desafio 04, Spurr) | V = 0,004095970 + 3,629759×10⁻⁵ · DAP² · H |
| Volume/ha do ponto | Vₕₐ = Σ Nᵢ · Vᵢ |
| Amostragem aleatória simples (AAS) | x̄ = ΣVₕₐ/n; s² = Σ(Vₕₐ − x̄)²/(n−1); Sx̄ = s/√n; EA = t₍n−1; 0,975₎·Sx̄; ER% = 100·EA/x̄; IC = x̄ ± EA |
| Total do talhão | x̄ · A e (x̄ ± EA) · A, com A = 25 ha |

## Premissas

1. **Modelos do Talhão 8 reaproveitados.** Os dois talhões têm a mesma filial (2), o mesmo clone (1501), a mesma idade (7 anos), o mesmo sítio (1) e o mesmo espaçamento (3 × 3 m). Isso torna a extrapolação razoável, mas ela não foi validada com dados do Talhão 20.
2. **Escolha da equação de volume.** O Desafio 04 selecionou Spurr porque teve o maior R² em validação cruzada (LOOCV): 0,987, com RMSE de 4,43%. Schumacher-Hall foi rodada como teste de sensibilidade.
3. **Grade sistemática processada como AAS**, sem correção para população finita. Essa escolha é conservadora, porque tende a superestimar a variância.
4. **Casca.** O volume segue a convenção da cubagem do Desafio 04 (Smalian sobre os diâmetros dᵢ medidos).

## Arquivos

- `desafio06_bitterlich.R`: script com quatro funções: `calc_expansao`, `estima_altura`/`estima_volume`, `resumo_ponto` e `processa_aas`
- `arvores_processadas.csv`, `resumo_por_ponto.csv`, `resumo_inventario.csv`: as três saídas exigidas no enunciado
- `resumo_area_basal.csv`: verificação independente dos modelos (área basal G/ha e número de árvores N/ha)
- `RELATORIO.md`: resultados e discussão
