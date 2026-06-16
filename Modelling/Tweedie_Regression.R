# =============================================================================
# TWEEDIE REGRESSION MODELING FOR VEHICLE INSURANCE CLAIM SIZE
# =============================================================================
# This script implements Tweedie Regression to model positive claim sizes
# conditional on claim occurrence, replicating the framework and parameters
# from Terefe & Aga (2026).
# =============================================================================

# 1. Load Required Libraries
library(readr)
library(dplyr)
library(statmod)   # For the tweedie family in glm()
library(ggplot2)
library(scales)

cat("========================================================\n")
cat("TAHAP 1: MEMUAT DAN MEMBERSIHKAN DATA\n")
cat("========================================================\n\n")

# 2. Load Dataset
# Using the master dataset (2011-2018) which matches the paper's n = 802,036 rows
data_path <- "vehicle_insurance_data/motor_data_master_11_18.csv"
if (!file.exists(data_path)) {
  stop("File data master tidak ditemukan di jalur: ", data_path)
}

cat("Memuat dataset dari:", data_path, "...\n")
motor_raw <- read_csv(data_path, col_types = cols(.default = col_character()))
cat("Data mentah berhasil dimuat. Dimensi:", nrow(motor_raw), "baris x", ncol(motor_raw), "kolom\n\n")

# 3. Filter Positive Claims (Conditional Severity Framework)
# The paper focuses on positive claim sizes conditional on claim occurrence (Y > 0)
motor_pos <- motor_raw %>%
  mutate(
    CLAIM_PAID = as.numeric(CLAIM_PAID),
    INSURED_VALUE = as.numeric(INSURED_VALUE),
    PREMIUM = as.numeric(PREMIUM),
    PROD_YEAR = as.numeric(PROD_YEAR)
  ) %>%
  filter(!is.na(CLAIM_PAID) & CLAIM_PAID > 0)

cat("Jumlah observasi klaim positif (Y > 0):", nrow(motor_pos), "\n")
cat("Persentase klaim positif dari seluruh portofolio:", 
    round(nrow(motor_pos) / nrow(motor_raw) * 100, 3), "%\n\n")

# 4. Feature Engineering and Grouping (Replicating Paper's Variables)
cat("Melakukan transformasi dan pengelompokan variabel prediktor...\n")
motor_clean <- motor_pos %>%
  mutate(
    # SEX: 0 = Legal Entity (Ref), 1 = Male, 2 = Female
    Sex = factor(SEX, levels = c("0", "1", "2"), labels = c("Legal Entity", "male", "female")),
    
    # INSR_TYPE: Commercial (1202) vs Private/Others (1201 & 1204 - Ref)
    InsuranceType_Comm = factor(ifelse(INSR_TYPE == "1202", "commercial", "private_others"), 
                                levels = c("private_others", "commercial")),
    
    # TYPE_VEHICLE grouped into 6 categories: Automobile (Ref), Bus, Pick-up, Station Wagon, Truck, others
    VehicleType = case_when(
      TYPE_VEHICLE == "Automobile" ~ "automobile",
      TYPE_VEHICLE == "Bus" ~ "bus",
      TYPE_VEHICLE == "Pick-up" ~ "pick-up",
      TYPE_VEHICLE == "Station Wagones" ~ "stationwagon",
      TYPE_VEHICLE == "Truck" ~ "truck",
      TRUE ~ "others"
    ),
    VehicleType = factor(VehicleType, levels = c("automobile", "bus", "others", "pick-up", "stationwagon", "truck")),
    
    # USAGE grouped into 6 categories: Fare Paying Passengers (Ref), Goods cartage, Other goods, Other service, private, others
    Usage_Group = case_when(
      USAGE == "Fare Paying Passengers" ~ "Fare Paying Passengers",
      USAGE == "General Cartage" ~ "Goods cartage",
      USAGE == "Own Goods" ~ "Other goods",
      USAGE == "Own service" ~ "Other service",
      USAGE == "Private" ~ "private",
      TRUE ~ "others"
    ),
    Usage_Group = factor(Usage_Group, levels = c("Fare Paying Passengers", "Goods cartage", "Other goods", "Other service", "others", "private")),
    
    # MAKE grouped into 6 categories: Bishoftu (Ref), Isuzu, Iveco, Nissan, Toyota, others
    Make_Group = case_when(
      MAKE == "TOYOTA" ~ "Toyota",
      MAKE == "ISUZU" ~ "Isuzu",
      MAKE == "NISSAN" ~ "Nissan",
      MAKE == "IVECO" ~ "Iveco",
      MAKE == "BISHOFTU" ~ "Bishoftu",
      TRUE ~ "others"
    ),
    Make_Group = factor(Make_Group, levels = c("Bishoftu", "Isuzu", "Iveco", "Nissan", "others", "Toyota")),
    
    # coverage: liability (if INSURED_VALUE = 0) vs comprehensive (Ref)
    coverage = factor(ifelse(INSURED_VALUE == 0, "liability", "comprehensive"), 
                      levels = c("comprehensive", "liability")),
    
    # Continuous Variables (Retained on original scale)
    Productionyear = PROD_YEAR,
    Insuredvalue = INSURED_VALUE,
    Premium = PREMIUM,
    
    # Response Variable: Natural Logarithm of Claim Paid (in Birr)
    # Note: Tweedie model is fitted on log(CLAIM_PAID) because it is always positive (> 1.6)
    # and ensures convergence under the log-link.
    y = log(CLAIM_PAID)
  ) %>%
  # Remove rows with NA in key variables
  filter(!is.na(Productionyear), !is.na(y))

cat("Jumlah observasi setelah penanganan missing values:", nrow(motor_clean), "\n\n")

# 5. Train-Test Split (70:30)
cat("========================================================\n")
cat("TAHAP 2: PEMBAGIAN DATA TRAIN & TEST (70:30)\n")
cat("========================================================\n")
set.seed(42)  # For reproducibility
train_idx <- sample(seq_len(nrow(motor_clean)), size = round(0.70 * nrow(motor_clean)))
train_data <- motor_clean[train_idx, ]
test_data  <- motor_clean[-train_idx, ]

cat("Ukuran data train :", nrow(train_data), "observasi\n")
cat("Ukuran data test  :", nrow(test_data), "observasi\n\n")

# 6. Fit Tweedie GLM (p = 2.5, Log-Link)
cat("========================================================\n")
cat("TAHAP 3: ESTIMASI MODEL TWEEDIE GLM (p = 2.5, Link = Log)\n")
cat("========================================================\n")
# Estimating parameters using the 70% training set
fit_tweedie <- glm(
  y ~ Sex + InsuranceType_Comm + VehicleType + Usage_Group + Make_Group + coverage + Productionyear + Insuredvalue + Premium,
  family = tweedie(var.power = 2.5, link.power = 0),  # link.power = 0 is the log link
  data = train_data
)

print(summary(fit_tweedie))

# Extracting dispersion parameter
dispersion <- summary(fit_tweedie)$dispersion
cat("\nDispersion Parameter (phi):", dispersion, "\n")
cat("Null Deviance:", fit_tweedie$null.deviance, "\n")
cat("Residual Deviance:", fit_tweedie$deviance, "\n\n")

# 7. Model Verification & Out-of-Sample Performance
cat("========================================================\n")
cat("TAHAP 4: VERIFIKASI MODEL DAN PERFORMA OUT-OF-SAMPLE\n")
cat("========================================================\n")
# Predict log claim size on test dataset
test_pred_log <- predict(fit_tweedie, newdata = test_data, type = "response")

# Convert back to original scale (Birr)
test_pred_orig <- exp(test_pred_log)
test_actual_orig <- test_data$CLAIM_PAID

# Compute RMSE on original scale
test_rmse <- sqrt(mean((test_actual_orig - test_pred_orig)^2, na.rm = TRUE))
cat("Root Mean Square Error (RMSE) Out-of-Sample (Birr):", format(round(test_rmse, 2), big.mark = ","), "\n\n")

# 8. Comparison table with Paper's Estimates
cat("========================================================\n")
cat("TAHAP 5: PERBANDINGAN PARAMETER ESTIMASI DENGAN PAPER\n")
cat("========================================================\n")
# Re-fitting on full dataset (100%) for maximum direct comparison to paper
fit_full <- glm(
  y ~ Sex + InsuranceType_Comm + VehicleType + Usage_Group + Make_Group + coverage + Productionyear + Insuredvalue + Premium,
  family = tweedie(var.power = 2.5, link.power = 0),
  data = motor_clean
)

coef_full <- coef(fit_full)
comparison <- data.frame(
  Variable = names(coef_full),
  Estimasi_Model_Kita = round(as.numeric(coef_full), 6),
  Estimasi_Paper = c(
    2.258,       # (Intercept)
    0.0362,      # Sexmale
    0.0296,      # Sexfemale
    0.0249,      # InsuranceTypecommercial
    -0.0060,     # VehicleTypebus
    0.0026,      # VehicleTypeothers
    -0.0428,     # VehicleTypepick-up
    0.0140,      # VehicleTypestationwagon
    -0.0281,     # VehicleTypetruck
    0.0499,      # UsageGoods cartage
    0.0157,      # UsageOther goods
    -0.0388,     # UsageOther service
    -0.0414,     # Usageothers
    -0.0364,     # Usageprivate
    0.0300,      # MakeIsuzu
    0.0134,      # MakeIveco
    0.0281,      # MakeNissan
    0.0222,      # Makeothers
    0.0311,      # MakeToyota
    -0.0897,     # coverageliability
    0.000037,    # Productionyear
    -6.55e-09,   # Insuredvalue
    1.17e-06     # Premium
  )
)
print(comparison)

# 9. Diagnostic Plot
cat("\nMembuat plot evaluasi aktual vs prediksi...\n")
plot_data <- data.frame(
  Aktual = test_actual_orig,
  Prediksi = test_pred_orig
)

# Plot actual vs predicted on log-log scale for readability
p <- ggplot(plot_data, aes(x = Aktual, y = Prediksi)) +
  geom_point(alpha = 0.2, color = "#4472C4") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", size = 1) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(
    title = "Prediksi vs Aktual Nilai Klaim Positif (Tweedie GLM)",
    subtitle = "Skala Log-Log (dalam Ethiopian Birr)",
    x = "Nilai Klaim Aktual",
    y = "Nilai Klaim Prediksi"
  ) +
  theme_minimal()

ggsave("Pre-Modelling/Tweedie_Actual_vs_Predicted.png", plot = p, width = 7, height = 5, dpi = 300)
cat("Plot diagnosis disimpan ke Pre-Modelling/Tweedie_Actual_vs_Predicted.png\n")
cat("\nProses selesai.\n")
