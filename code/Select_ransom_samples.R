# Install and load the pacman library if it's not already installed
if (!require(pacman)) install.packages("pacman")

# Packages to install and load
packages <- c("here","sf", "terra", "dplyr", "sp", "ggplot2")

# Install and load the packages
p_load_gh(packages)

# Define the path to the shapefile------------------------------------
shape_path <- here("data", "vector", "samples_18clas_500_each_class.shp")
shape_class <- st_read(shape_path)


# Ensure the 'EUNIS_new' column exists
if (!("EUNIS_new" %in% names(shape_class))) {
  stop("Column 'EUNIS_new' not found in the shapefile")
}

# Function to sample points and assign types
sample_and_assign_type <- function(df, size_per_class = 500, type_T_ratio = 0.7) {
  # Sample points
  sampled <- df %>%
    group_by(EUNIS_new) %>%
    sample_n(size = size_per_class, replace = FALSE)

  # Assign Type T or V
  sampled <- sampled %>%
    group_by(EUNIS_new) %>%
    mutate(Type = ifelse(row_number() <= size_per_class * type_T_ratio, "T", "V"))

  return(sampled)
}

# Apply the function to the data (shape_class)
result <- sample_and_assign_type(shape_class)

### Save the result (optional)
# output_dir_S <- here("data", "results", "shapes")
# output_file_S <- "result18.shp"
# rout_save_S <- file.path(output_dir_S, output_file_S)
# writeRaster(result, rout_save_S, overwrite = TRUE)

# Reducing classes---------------------------------------------------------------------------------------------------------------------
# Define class fusions as a list
fusions <- list(
  T195_semplified = c("T195", "T195_C", "T195_M"),
  T1E1_semplified = c("T1E1", "T1E1_C", "T1E1_M")
)

# Apply class fusions
for (final_name in names(fusions)) {
  classes_to_merge <- fusions[[final_name]]
  result$EUNIS_simpl[result$EUNIS_new %in% classes_to_merge] <- final_name
}

# For classes that do not change, simply copy the name
unchanged_classes <- setdiff(unique(result$EUNIS_new), unlist(fusions))
result$EUNIS_simpl[result$EUNIS_new %in% unchanged_classes] <- result$EUNIS_new[result$EUNIS_new %in% unchanged_classes]

# Function to sample while maintaining the proportion of T and V
sample_maintaining_proportion <- function(df, size_per_class = 500, type_T_ratio = 0.7) {
  # Ensure the 'Type' column exists
  if (!"Type" %in% names(df)) {
    stop("Column 'Type' not found in the dataframe")
  }

  # Sample proportionally T and V
  df_T <- df %>% filter(Type == "T") %>% sample_n(size = round(size_per_class * type_T_ratio), replace = FALSE)
  df_V <- df %>% filter(Type == "V") %>% sample_n(size = size_per_class - round(size_per_class * type_T_ratio), replace = FALSE)

  # Combine the results
  rbind(df_T, df_V)
}

# Perform sampling for each simplified class maintaining the proportion
result_sampled <- result %>%
  group_by(EUNIS_simpl) %>%
  do(sample_maintaining_proportion(., size_per_class = 500, type_T_ratio = 0.7))

# Create a new column 'Type2' based on the existing 'Type' column
result_sampled <- result_sampled %>%
  mutate(Type2 = Type)

# Verify each class has 500 points and the proportion of T and V
table(result_sampled$EUNIS_simpl, result_sampled$Type2)

### Save the result (optional)
# output_dir_S <- here("data", "results", "shapes")
# output_file_S <- "samples_S2_14clas.shp"
# rout_save_S <- file.path(output_dir_S, output_file_S)
# writeRaster(result_sampled, rout_save_S, overwrite = TRUE)
