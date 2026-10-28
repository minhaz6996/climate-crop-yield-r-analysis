#!/usr/bin/env Rscript
# Climate and crop yield: reproducible analysis from the supplied secondary dataset
# Cleaned and organized from the original d.R and thesis methodology.
# Research, manuscript development, R scripting, statistical analysis
# and visualisations by Minhazul Alam (per project creator's clarification).
# This is a research-work portfolio project, not a claim of a degree thesis
# formally submitted by Minhazul Alam.
# Run from repository root: Rscript src/analysis.R
# Optional alternate path: Rscript src/analysis.R path/to/your.csv
# Requires only base R (no install.packages() calls).

args <- commandArgs(trailingOnly = TRUE)
csv_file <- if (length(args) > 0) args[1] else file.path("data", "climate_agriculture.csv")
if (!file.exists(csv_file)) stop("Dataset not found: ", csv_file)

dat <- read.csv(csv_file, check.names = FALSE, stringsAsFactors = FALSE)
expected <- c(
  "year", "country", "region", "crop_type", "average_temperature_c",
  "total_precipitation_mm", "co2_emissions_mt", "crop_yield_mt_per_ha",
  "extreme_weather_events", "irrigation_access_percentage",
  "pesticide_use_kg_per_ha", "fertilizer_use_kg_per_ha", "soil_health_index",
  "adaptation_strategies", "economic_impact_million_usd"
)
# Accept both the cleaned repository CSV and the original supplied CSV.
original <- c(
  "Year", "Country", "Region", "Crop_Type", "Average_Temperature_C",
  "Total_Precipitation_mm", "CO2_Emissions_MT", "Crop_Yield_MT_per_HA",
  "Extreme_Weather_Events", "Irrigation_Access_%", "Pesticide_Use_KG_per_HA",
  "Fertilizer_Use_KG_per_HA", "Soil_Health_Index",
  "Adaptation_Strategies", "Economic_Impact_Million_USD"
)
if (identical(names(dat), original)) names(dat) <- expected
if (!all(expected %in% names(dat))) {
  stop("Expected columns are missing: ", paste(setdiff(expected, names(dat)), collapse = ", "))
}

dat$crop_type <- factor(dat$crop_type)
dat$adaptation_strategies <- factor(dat$adaptation_strategies)
num_cols <- setdiff(expected, c("country", "region", "crop_type", "adaptation_strategies"))
for (col in num_cols) dat[[col]] <- as.numeric(dat[[col]])
if (anyNA(dat[, num_cols])) stop("Numeric fields contain missing or nonnumeric values; inspect inputs")

if (!dir.exists("results")) dir.create("results", recursive = TRUE)
if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

climate <- c("average_temperature_c", "total_precipitation_mm",
             "co2_emissions_mt", "extreme_weather_events")
inputs <- c("irrigation_access_percentage", "pesticide_use_kg_per_ha",
            "fertilizer_use_kg_per_ha", "soil_health_index")
response <- "crop_yield_mt_per_ha"
model1 <- lm(reformulate(climate, response), data = dat)
model2 <- lm(reformulate(c(climate, inputs), response), data = dat)
model3 <- lm(reformulate(c(climate, inputs, "crop_type", "adaptation_strategies"), response), data = dat)
model4 <- lm(reformulate(c(climate, inputs, paste0("I(", climate, "^2)")), response), data = dat)
models <- list("Baseline climate" = model1, "Main linear" = model2,
               "Controlled" = model3, "Extended nonlinear" = model4)

model_rows <- lapply(names(models), function(nm) {
  fit <- models[[nm]]; s <- summary(fit)
  data.frame(model = nm, n = nobs(fit), r_squared = s$r.squared,
             adjusted_r_squared = s$adj.r.squared,
             f_test_p_value = pf(s$fstatistic[[1]], s$fstatistic[[2]],
                                 s$fstatistic[[3]], lower.tail = FALSE),
             aic = AIC(fit), bic = BIC(fit))
})
model_summary <- do.call(rbind, model_rows)
write.csv(model_summary, "results/model_comparison.csv", row.names = FALSE)

coef_rows <- lapply(names(models), function(nm) {
  out <- as.data.frame(summary(models[[nm]])$coefficients)
  data.frame(model = nm, term = rownames(out), estimate = out[[1]],
             std_error = out[[2]], t_statistic = out[[3]], p_value = out[[4]],
             row.names = NULL, check.names = FALSE)
})
write.csv(do.call(rbind, coef_rows), "results/model_coefficients.csv", row.names = FALSE)

corr_cols <- c(climate[1:3], response, climate[4], inputs)
corr <- cor(dat[, corr_cols], use = "complete.obs", method = "pearson")
write.csv(round(corr, 6), "results/correlation_matrix.csv")

png("figures/01_yearly_crop_yield.png", 1200, 650, res = 130)
yr <- aggregate(dat$crop_yield_mt_per_ha, list(year = dat$year), mean)
plot(yr$year, yr$x, type = "o", pch = 19, col = "#3269CF", lwd = 2,
     main = "Year-wise Average Crop Yield", xlab = "Year", ylab = "Yield (MT/ha)")
grid(col = "#dfe6f1"); dev.off()

png("figures/02_crop_yield_by_crop.png", 1200, 700, res = 130)
cr <- sort(tapply(dat$crop_yield_mt_per_ha, dat$crop_type, mean))
par(mar = c(5, 11, 4, 2))
barplot(cr, horiz = TRUE, las = 1, col = "#3269CF",
        main = "Average Crop Yield by Crop", xlab = "Yield (MT/ha)")
dev.off()


png("figures/03_correlation_heatmap.png",
    width = 1700, height = 1600, res = 130)

heatmap(
  corr,
  Rowv = NA,
  Colv = NA,
  symm = TRUE,
  scale = "none",
  margins = c(22, 20),
  cexRow = 0.85,
  cexCol = 0.85,
  breaks = seq(-1, 1, length.out = 121),
  col = colorRampPalette(
    c("#d65e5e", "#ffffff", "#3269cf")
  )(120),
  main = "Pearson Correlation Heatmap"
)

dev.off()


png("figures/04_temperature_scatter.png", 1100, 650, res = 130)
plot(dat$average_temperature_c, dat$crop_yield_mt_per_ha, pch = 19,
     col = "#3269CF99", main = "Temperature vs. Crop Yield",
     xlab = "Average temperature (°C)", ylab = "Crop yield (MT/ha)")
abline(lm(crop_yield_mt_per_ha ~ average_temperature_c, data = dat), col = "#f77670", lwd = 3)
dev.off()

png("figures/05_co2_scatter.png", 1100, 650, res = 130)
plot(dat$co2_emissions_mt, dat$crop_yield_mt_per_ha, pch = 19,
     col = "#3269CF99", main = "CO₂ Emissions vs. Crop Yield",
     xlab = "CO₂ emissions (MT)", ylab = "Crop yield (MT/ha)")
abline(lm(crop_yield_mt_per_ha ~ co2_emissions_mt, data = dat), col = "#f77670", lwd = 3)
dev.off()

png("figures/06_model_r_squared.png", 1100, 640, res = 130)
par(mar = c(5, 13, 4, 2))
barplot(rev(model_summary$r_squared), names.arg = rev(model_summary$model),
        horiz = TRUE, las = 1, col = c("#f77670", rep("#3269cf", 3)),
        main = "Regression Model Fit Comparison", xlab = "R-squared")
dev.off()

cat("Data rows:", nrow(dat), "| Columns:", ncol(dat), "\n")
print(model_summary[, c("model", "r_squared", "adjusted_r_squared", "f_test_p_value")])
cat("\nResults and figures saved to results/ and figures/.\n")
