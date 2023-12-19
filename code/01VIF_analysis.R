# Install and load the pacman library if it's not already installed
if (!require(pacman)) install.packages("pacman")

# Packages to install and load
packages <- c("here", "raster", "sf", "terra", "usdm", "randomForest")

# Install and load the packages
p_load_gh(packages)

# Load the study area raster -----------------
area_raster_path <- here("data", "raster", "Limit.tif")
area_raster <- rast(area_raster_path)
plot(area_raster[[1]])

# Load the Sentinel 2 spectral indices raster----------------------
#raster_indices_path <- here("G:/My Drive/GEE/S2_20m.tif")
raster_indices_path <- here("data", "raster", "S2_20m.tif") #S2_20m.tif <- https://drive.google.com/file/d/1bWFpkF4xD-XFNjUuXoKNMzJIi1YFPuv_/view?usp=sharing
raster_indices <- rast(raster_indices_path)
plot(raster_indices[[15]])

# Ensure both rasters have the same projection--------------------------------
if (!crs(raster_indices) %in% crs(area_raster)) {
  cat("Converting the projection of raster_indices to match area_raster...\n")
  # Reproject raster_indices to the same projection as area_raster
  raster_indices <- projectRaster(raster_indices, crs = crs(area_raster))
}

# Convert the study area into a polygon ------------------------------------------------
area_poly <- as.polygons(area_raster, dissolve = TRUE)
# Rasterize the polygon with the same resolution and extent as raster_indices
a_raster_res <- rasterize(area_poly, raster_indices, field = 1, background = NA)

# Apply the mask to clip according to the study area limits
raster_indices_mask <- mask(raster_indices, a_raster_res)
plot(raster_indices_mask[[15]])

# Extract band names-------------
indices_names <- names(raster_indices_mask)
print(indices_names)

#Raster to a dataframe--------------------------------------------
df_raster_i <- na.omit(raster::as.data.frame(raster_indices_mask, xy = TRUE))[, -c(1, 2)]

#############################Var important analysis (10) -----------------------------------------

# Train a Random Forest model
df_raster_i2 <- df_raster_i
df_raster_i2$target <- sample(c(0, 1), nrow(df_raster_i2), replace = TRUE)

model <- randomForest(target ~ ., data = df_raster_i2, ntree = 100, importance = TRUE) #RF model

# Get model importances
importance_values <- importance(model)

# Sort importances in descending order and get the top 10 most important variables
top_10_indices <- order(importance_values[, 1], decreasing = TRUE)[1:10]

# Get the names of the top 10 variables
top_10_names <- rownames(importance_values)[top_10_indices]

# Visualize the names of the top 10 variables
print(top_10_names)

# Subset the raster to keep only the selected important bands (indices)
VarImport_indices <- c("IPVI", "NDVI", "OSAVI", "GDVI", "GNDVI", "ATSAVI", "SR", "EVI2", "MSR", "DVI")
raster_indices_varimp <- raster_indices_mask[[VarImport_indices]]
plot(raster_indices_varimp)

#####################################Calculate VIF --------------------------------------------------------------

# Calculate VIF
VIF <- vifstep(x = raster_indices_varimp, th = 5, keep = NULL, method = 'pearson')
print(VIF)
# 8 variables from the 10 input variables have collinearity problem:
#
#   IPVI OSAVI MSR EVI2 ATSAVI NDVI GNDVI SR
#
# After excluding the collinear variables, the linear correlation coefficients ranges between:
#   min correlation ( DVI ~ GDVI ):  0.7100797
# max correlation ( DVI ~ GDVI ):  0.7100797
#
# ---------- VIFs of the remained variables --------
#   Variables      VIF
# 1      GDVI 2.016996
# 2       DVI 2.016996

# VIF variables
VIF_variables <- c("GDVI", "DVI")

# Subset the raster to keep only the selected bands
raster_to_clasif <- raster_indices_varimp[[VIF_variables]]
plot(raster_to_clasif)


### Save raster --------------------------------
output_dir_R <- here("data", "results")
output_file_R <- "raster_VIF_s2.tif"
rout_save_R <- file.path(output_dir_R, output_file_R)
writeRaster(raster_to_clasif, rout_save_R, overwrite = TRUE)







