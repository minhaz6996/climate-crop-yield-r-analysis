# Verification & publication checklist

## Scope of verification

- The supplied `Main Dataset(1).csv` contained **199 rows** and **15 columns**.
- Missing values across source fields: **0**.
- Exact duplicate rows: **0**.
- Year range: **1990–2024**.
- Four OLS regression specifications and Pearson correlations independently reproduced using Python `statsmodels` / `pandas`.
- Reported main R² matches thesis rounding: **0.102164**, extended R² **0.208355**.
- Original `d.R` has repeated `install.packages`, machine-specific paths, exploratory non-running placeholder variable names, and manually entered sample figures. These are not retained in the new clean script.
- The reconstructed base-R analysis script was successfully executed in RStudio using R 4.4.2. All four regression models produced results consistent with the independently verified Python calculations. Three results CSV files and six figures were generated successfully.
- The original portfolio preview figures were independently generated using Python. Two additional RStudio-generated figures, `R_03_correlation_heatmap.png` and `R_06_model_r_squared.png`, were subsequently verified and published separately.
## Before publishing to GitHub

1. Credit Minhazul Alam for the research and manuscript development, R programming, statistical analysis, and visualizations based on his clarification. The name listed as the academic submitter in the source manuscript does not by itself determine who performed the work. Do **not** represent this portfolio project as a thesis formally submitted by Minhazul Alam for his own degree.
2. Confirm the secondary dataset's source, license and permission to redistribute; **if uncertain, do not publish data/**. Keep it locally and update README with a download/data-access instruction you are authorized to provide.
3. Publish only figures and materials you are entitled to share; this package uses independently recomputed charts.
4. Run `Rscript src/analysis.R` in a local R installation and confirm outputs.
5. Inspect exported charts, model table and categorical-control treatment; do not assert causal findings.
6. Add only this repository's extracted files at the repository **root**, maintaining the folder hierarchy.
7. Update profile `README.md` with a link and banner image only after the new repository is public and tested.

## Suggested repository

`climate-crop-yield-r-analysis` — separate from the existing PostgreSQL project.

## Suggested commit

`Add climate crop yield R statistical research portfolio`
