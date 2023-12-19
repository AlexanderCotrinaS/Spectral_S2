# Install and load the pacman library if it's not already installed
if (!require(pacman)) install.packages("pacman")

# Packages to install and load
packages <- c("here", "raster", "sf", "terra")

# Install and load the packages
p_load_gh(packages)

# Load the CHM raster
CHM_raster_path <- here("data", "raster", "CHM_clip.tif")
CHMSD_raster_path <- here("data", "raster", "CHMSD_clip.tif")

CHM_raster <- rast(CHM_raster_path)
CHMSD_raster <- rast(CHMSD_raster_path)
plot(CHM_raster)
plot(CHMSD_raster)

# Resampling-------------------------------------------
# Import raster base
S2_VIF_path <- here("data", "results", "raster_VIF_s2.tif")
S2_VI_raster <- rast(S2_VIF_path)

# Define the target CRS
target_crs <- crs(S2_VI_raster)

# Reproject CHM rasters using the target CRS
CHM_proj <- project(CHM_raster, target_crs)
CHMSD_proj <- project(CHMSD_raster, target_crs)

# Ensure both rasters have the same resolution
CHM_resampled <- resample(CHM_proj, S2_VI_raster, method = "near")
CHMSD_resampled <- resample(CHMSD_proj, S2_VI_raster, method = "near")

# Apply the mask to the resampled rasters
r_crop_path <- here("data", "results", "raster_crop.tif")
a_raster_res <- rast(r_crop_path)

CHM_mask <- mask(CHM_resampled, a_raster_res)
CHMSD_mask <- mask(CHMSD_resampled, a_raster_res)

# Combine the rasters
raster_VIF_CHM <- c(S2_VI_raster, CHM_mask, CHMSD_mask)

# Assign names to the additional bands
names(raster_VIF_CHM) <- c(names(S2_VI_raster), "CHM", "CHMSD")

# Visualize the combined raster
plot(raster_VIF_CHM)

### Save raster --------------------------------
output_dir_R <- here("data", "results")
output_file_R <- "raster_VIF_CHM.tif"
rout_save_R <- file.path(output_dir_R, output_file_R)
writeRaster(raster_VIF_CHM, rout_save_R, overwrite = TRUE)


