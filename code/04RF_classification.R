# Install and load the pacman library if it's not already installed
if (!require(pacman)) install.packages("pacman")

# Packages to install and load
packages <- c("here", "raster", "sf", "terra", "usdm", "randomForest", "caret", "sp", "ggplot2")

# Install and load the packages
p_load_gh(packages)

# Define the path to the shapefile------------------------------------
shp_path <- here("data", "vector", "samples_S2_14clas.shp")
shape_class <- st_read(shp_path)

# Define the path to the raster to classify ------------------------------
rVIF_CHM_path <- here("data", "results", "raster_VIF_CHM.tif")
r_VIF_CHM <- stack(rVIF_CHM_path)
plot(r_VIF_CHM)

# Check if projections match; if not, reproject one of them
if (!identical(st_crs(shape_class), projection(r_VIF_CHM))) {
  shape_class <- st_transform(shape_class, crs = projection(r_VIF_CHM))
}

# Extract North and East (or East and West) coordinates---------
#shape_class$North <- st_coordinates(shape_class)[, "Y"]
#shape_class$East <- st_coordinates(shape_class)[, "X"] # If interested

#Create a new DataFrame with columns, Simpl_2, and Type2
new_df_shp <- shape_class[, c("EUNIS_s", "Type2")]
new_df_shp$geometry <- NULL

# Extract raster values at shapefile locations--------------------------------------
raster_values <- extract(r_VIF_CHM, shape_class)

# Combine raster values with the new DataFrame
classification_data <- cbind(new_df_shp, raster_values)

# Split data into training and validation sets---------------------------------------------------
training_data <- classification_data[classification_data$Type2 == "T", ]
validation_data <- classification_data[classification_data$Type2 == "V", ]

training_data$EUNIS_s <- as.factor(training_data$EUNIS_s)
validation_data$EUNIS_s <- as.factor(validation_data$EUNIS_s)

# missing_values_train <- colSums(is.na(training_data))
# missing_values_valid <- colSums(is.na(validation_data))
# # Display columns with missing values
# print("Missing values in ....")
# print(missing_values_train[missing_values_train > 0])
# print(missing_values_valid[missing_values_valid > 0])

# Train the Random Forest model-------------------------------------------------------
# Train the Random Forest model-------------------------------------------------------
# Remove rows with missing values
training_data <- na.omit(training_data)
validation_data <- na.omit(validation_data)

# Select only the relevant columns for the model
training_data_model <- training_data[, -which(names(training_data) == "Type2")]

# Retrain the Random Forest model
rf_model <- randomForest(EUNIS_s ~ ., data = training_data_model, ntree = 500)

# Predict classifications for each cell of the raster
predicted_raster <- predict(r_VIF_CHM, rf_model, type="response")
plot(predicted_raster)

# Predict on the validation set (excluding Type2)
validation_predictions <- predict(rf_model, validation_data[, -which(names(validation_data) == "Type2")])

# Generate a confusion matrix
confusion_matrix <- confusionMatrix(validation_predictions, validation_data$EUNIS_s)
print(confusion_matrix)

# Calculate Overall Accuracy (OA) and Kappa------------------------------------
OA <- confusion_matrix$overall['Accuracy']
Kappa <- confusion_matrix$overall['Kappa']

# Calculate User's Accuracy (UA) and Producer's Accuracy (PA) for each class
conf_matrix <- confusion_matrix$table
UA <- diag(prop.table(conf_matrix, 1))
PA <- diag(prop.table(conf_matrix, 2))

# Print results
print(OA)
print(Kappa)
print(UA)
print(PA)

# Create a vector with class names------------------------------------------------------------
class_names <- rownames(conf_matrix)

# Create a DataFrame with classes, UA, and PA
results_by_class <- data.frame(Class = class_names, UA = UA, PA = PA)
# Round UA and PA to two decimal places in the data frame
results_by_class$UA <- round(results_by_class$UA, 2)
results_by_class$PA <- round(results_by_class$PA, 2)
results_by_class <- results_by_class[-1]

print(results_by_class)


#######-------------------------------------------------------------------------------
# Class names
class_names <- c("Agricoli", "Arbusti", "Aree in r*", "N1G", "P_S", "Pascoli",
                 "Pascoli_a", "S51", "Spiaggia", "T195_semplified", "T19B6",
                 "T1E1_semplified", "T211", "T212")

# Define a color vector, one for each class
class_colors <- c("green", "peru", "lightblue", "forestgreen", "olivedrab", "yellowgreen",
                  "#FFE8B2","darkolivegreen","yellow", "saddlebrown", "#F39B7F", "#008080",
                  "#808080", "#860086") # Replace with desired colors

# Convert the raster to a categorized raster
predicted_raster <- raster::ratify(predicted_raster)

# Get the attribute table of the raster
rat <- levels(predicted_raster)[[1]]

# Assign names and colors to the categories
rat$names <- class_names
rat$color <- class_colors
levels(predicted_raster) <- rat

# Plot the raster with defined colors
plot(predicted_raster, col=rat$color, main="Raster Classification")

# Add legend
legend("topright", legend=class_names, fill=class_colors, cex=0.7)

######----------------------------------------
### Save raster --------------------------------
output_dir_R <- here("data", "results")
output_file_R <- "raster_clasif.tif"
rout_save_R <- file.path(output_dir_R, output_file_R)
writeRaster(predicted_raster, rout_save_R, overwrite = TRUE)
