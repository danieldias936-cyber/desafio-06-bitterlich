# Relatório — Inventário do Talhão 20 por Amostragem de Bitterlich

## Resultados (n = 25 pontos; t₍24; 0,975₎ = 2,0639)

| Estimativa | Valor |
|---|---|
| Volume médio | **370,13 m³/ha** |
| Variância | 15.220,82 (m³/ha)² |
| Desvio-padrão | 123,37 m³/ha (CV = 33,3%) |
| Erro-padrão da média | 24,67 m³/ha |
| Erro absoluto | ±50,93 m³/ha |
| Erro relativo | **13,76%** |
| IC 95% por hectare | 319,21 a 421,06 m³/ha |
| Volume total (25 ha) | **9.253,3 m³** |
| IC 95% do total | 7.980,2 a 10.526,4 m³ |

Verificação independente dos modelos de altura e volume: área basal G = 27,36 m²/ha (ER 13,6%) e número de árvores N = 1.242 árv/ha (ER 15,7%).

Teste de sensibilidade com Schumacher-Hall no lugar de Spurr: 366,55 m³/ha (ER 13,82%), total de 9.163,9 m³. A diferença é de −1,0%, bem menor que o erro amostral.

## Discussão

**O erro relativo é aceitável?** Não, pelo critério usual. O erro de 13,76% fica acima do limite de 10% (com 95% de probabilidade) normalmente exigido em inventários de povoamentos plantados. A causa é a alta variabilidade entre pontos (CV de 33%). O número de árvores contadas por ponto variou de 3 a 14 (área basal de 9 a 42 m²/ha), e a variabilidade do volume vem quase toda daí: o ER do volume (13,8%) é praticamente igual ao da área basal (13,6%). O número de pontos necessário para atingir 10% de erro é n ≈ (t·CV/E)² ≈ (2,06 · 33,3 / 10)² ≈ 47. Outra opção seria um FAB menor (por exemplo, 2 m²/ha), que aumenta o número de árvores contadas por ponto e reduz a variância entre pontos. A grade sistemática foi processada como AAS, o que tende a superestimar a variância. O erro "verdadeiro" provavelmente é um pouco menor, mas dificilmente cai abaixo de 10%.

**Limitações de usar os modelos do Talhão 8:**
1. **Extrapolação de diâmetro.** A relação hipsométrica foi calibrada com DAP de 9,6 a 21,9 cm, e 30 das 228 árvores ficam fora dessa faixa. A equação de volume foi calibrada com DAP de até 18,7 cm, e 97 árvores (43%) estão acima disso. Como as árvores grossas carregam boa parte do volume por ponto, o erro de modelo pode ser relevante.
2. **Comportamento do Chapman-Richards fora da faixa.** Com b₂ = 5,33, a curva despenca para DAP pequenos. A árvore de 6 cm (ponto 18) recebeu altura de 6,4 m, o que é implausível para um povoamento clonal de 7 anos. O impacto no volume é pequeno, porque a árvore é fina, mas mostra o risco.
3. **Mesma curva para todo o talhão.** Mesmo com clone, idade e sítio iguais, o Talhão 20 pode ter outra relação altura–diâmetro (densidade, manejo, microssítio). A altura estimada não reflete diferenças reais entre os talhões, o que gera viés que não aparece no erro amostral.
4. **O erro amostral subestima a incerteza total.** O IC considera só a variação entre pontos. O erro de predição dos modelos (RMSE de 4,4% no volume, mais o erro da hipsometria) não está incluído.
5. **Recomendação:** medir as alturas de uma subamostra de árvores nos pontos do Talhão 20 para validar (ou reajustar) a relação hipsométrica, e cubar algumas árvores grossas (DAP > 19 cm) para estender a faixa de calibração da equação de volume.
