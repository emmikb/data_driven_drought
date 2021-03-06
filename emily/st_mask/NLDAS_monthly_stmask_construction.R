library(rgdal)
library(raster)
library(sp)

setwd("/nfs/datadrivendroughteffect-data/Data/Masks/")

#####################################################################################################################################
# LOAD DATA
#####################################################################################################################################

#load data
data <- raster('/nfs/datadrivendroughteffect-data/Data/Masks/sample_data/NLDAS_sample.nc')
n <- 12 #time step within year
doy <- seq(from = 1, to = 364, by = 31) 

#####################################################################################################################################
# TEMPORAL MASK
#####################################################################################################################################

#seasonal stop/start information
soy_start_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Soybeans.crop.calendar.fill/plant.start.asc'
soy_stop_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Soybeans.crop.calendar.fill/harvest.end.asc'
wheat_start_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Wheat.crop.calendar.fill/plant.start.asc'
wheat_stop_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Wheat.crop.calendar.fill/harvest.end.asc'
maize_start_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Maize.crop.calendar.fill/plant.start.asc'
maize_stop_fn <- '/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/ALL_CROPS_ArcINFO_5min_filled/Maize.crop.calendar.fill/harvest.end.asc'

#processing function
image_prep <- function(filename){
  ras <- raster(filename)
  crs(ras) <- "+init=epsg:4326"
  ras <- projectRaster(ras, crs = projection(data))
  ras <- crop(ras, data)
  ras <- resample(ras, data, method="ngb")
  return(ras)
}

#create stop/start rasters
soy_start <- image_prep(soy_start_fn)
soy_stop <- image_prep(soy_stop_fn)
wheat_start <- image_prep(wheat_start_fn)
wheat_stop <- image_prep(wheat_stop_fn)
maize_start <- image_prep(maize_start_fn)
maize_stop <- image_prep(maize_stop_fn)

#soy mask
soy_start[is.na(soy_start)] <- 0
soy_start_mask <- stack(mget(rep("soy_start",n)))
soy_stop[is.na(soy_stop)] <- 0
soy_stop_mask <- stack(mget(rep("soy_stop",n)))
soy_stack <-  stack(mget(rep("data",n)))
for (i in 1:n) {
  idx <- doy[i]
  soy_stack[[i]] <- setValues(soy_stack[[i]], idx)
}

soy_stack_eom <- soy_stack + 31
soy_stack[soy_stack < soy_start_mask] <- NA
soy_stack[soy_stack_eom > soy_stop_mask] <- NA

#wheat mask
wheat_start[is.na(wheat_start)] <- 0
wheat_start_mask <- stack(mget(rep("wheat_start",n)))
wheat_stop[is.na(wheat_stop)] <- 0
wheat_stop_mask <- stack(mget(rep("wheat_stop",n)))
wheat_stack <-  stack(mget(rep("data",n)))
for (i in 1:n) {
  idx <- doy[i]
  wheat_stack[[i]] <- setValues(wheat_stack[[i]], idx)
}
wheat_stack_eom <- wheat_stack + 31
wheat_stack[wheat_stack < wheat_start_mask] <- NA
wheat_stack[wheat_stack_eom > wheat_stop_mask] <- NA

#maize mask
maize_start[is.na(maize_start)] <- 0
maize_start_mask <- stack(mget(rep("maize_start",n)))
maize_stop[is.na(maize_stop)] <- 0
maize_stop_mask <- stack(mget(rep("maize_stop",n)))
maize_stack <-  stack(mget(rep("data",n)))
for (i in 1:n) {
  idx <- doy[i]
  maize_stack[[i]] <- setValues(maize_stack[[i]], idx)
}
maize_stack_eom <- maize_stack + 31
maize_stack[maize_stack < maize_start_mask] <- NA
maize_stack[maize_stack_eom > maize_stop_mask] <- NA

#average agricultural start/stop dates

image_prep_time <- function(filename){
  ras <- raster(filename)
  #crs(ras) <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs "
  ras <- projectRaster(ras, crs = projection(data))
  ras <- crop(ras, data)
  ras <- resample(ras, data, method="ngb")
  return(ras)
}

start <- image_prep_time('/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/start.tif')
start[is.na(start)] <- 0
start_mask <- stack(mget(rep("start",n)))
stop <- image_prep_time('/nfs/datadrivendroughteffect-data/Data/Seasonal_stop_start/stop.tif')
stop[is.na(stop)] <- 0
stop_mask <- stack(mget(rep("stop",n)))
ag_stack <- stack(mget(rep("data",n)))
for (i in 1:n) {
  idx <- doy[i]
  ag_stack[[i]] <- setValues(ag_stack[[i]], idx)
}
ag_stack_eom <- ag_stack + 31
ag_stack[ag_stack < start_mask] <- NA
ag_stack[ag_stack_eom > stop_mask] <- NA

remove(start_mask, stop_mask, soy_start_mask, soy_stop_mask, wheat_start_mask, wheat_stop_mask, maize_start_mask, maize_stop_mask)

writeRaster(soy_stack, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_soy.nc", format="CDF", overwrite=T)
writeRaster(wheat_stack, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_wheat.nc", format="CDF", overwrite=T)
writeRaster(maize_stack, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_maize.nc", format="CDF", overwrite=T)
writeRaster(ag_stack, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_agriculture.nc", format="CDF",overwrite=T)

#####################################################################################################################################
# CATEGORICAL SPATIAL MASK
#####################################################################################################################################

soy <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_soy.nc")
wheat <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_wheat.nc")
maize <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_maize.nc")
ag <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_agriculture.nc")

lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/we_run/NLDAS_lulc_final.tif")
lulc_mask <- stack(mget(rep("lulc",n)))

#crop subset
#wheat listed as (24) winter wheat which grows from September to November, (22) durum wheat and (23) spring wheat
#since we focus on the spring/summer growing season, wheat == 22 and 23
wheat[lulc_mask > 23] <- NA
wheat[lulc_mask < 22] <- NA

#soy == 5
soy[lulc_mask != 5] <- NA

#maize == 1
maize[lulc_mask != 1] <- NA

#write out
writeRaster(wheat, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_wheat.nc", format="CDF", overwrite=T)
writeRaster(soy, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_soy.nc", format="CDF", overwrite=T)
writeRaster(maize, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_maize.nc", format="CDF", overwrite=T)


#ag/eco flag
# test <- raster("/nfs/datadrivendroughteffect-data/Data/Landuse/lulc_bin.tif")
# ras_ag <- aggregate(test, fact=30, fun=modal, na.rm=T)
# ras_prj <- projectRaster(ras_ag, crs=projection(data))
# ras_crp <- crop(ras_prj, data)
# lulc_bin <- resample(ras_crp, data, method="ngb")
# writeRaster(lulc_bin, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/lulc_mode/NLDAS_lulc_bin.nc", format="CDF",overwrite=T)

lulc_bin <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_mode/NLDAS_lulc_bin.nc") #eco == 1, agro == 2
lulc_bin_mask <- stack(mget(rep("lulc_bin",n)))
writeRaster(lulc_bin_mask, "/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_ecological.nc")

ag[lulc_bin_mask != 2] <- NA

eco <- lulc_bin_mask
eco[eco != 1] <- NA

writeRaster(ag, "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_agriculture.nc", format="CDF", overwrite=T)
writeRaster(eco, "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_ecological.nc", format="CDF", overwrite=T)


#####################################################################################################################################
# FRACTION SPATIAL MASK
#####################################################################################################################################

#open time masks
wheat <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_wheat.nc")
soy <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_soy.nc")
maize <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_maize.nc")
ag <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_agriculture.nc")
eco <- brick("/nfs/datadrivendroughteffect-data/Data/Masks/time_masks/NLDAS_monthly_ecological.nc") #where == 1

#land use fraction rasters
wheat_lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_frac/wheat_nldas.nc")
soy_lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_frac/soy_nldas.nc")
maize_lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_frac/maize_nldas.nc")
ag_lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_frac/ag_nldas.nc")
eco_lulc <- raster("/nfs/datadrivendroughteffect-data/Data/Masks/lulc_frac/eco_nldas.nc")

#land use fraction masks
wheat_lulc_mask <- stack(mget(rep("wheat_lulc",n)))
soy_lulc_mask <- stack(mget(rep("soy_lulc",n)))
maize_lulc_mask <- stack(mget(rep("maize_lulc",n)))
ag_lulc_mask <- stack(mget(rep("ag_lulc", n)))
eco_lulc_mask <- stack(mget(rep("eco_lulc", n)))

#wheat
wheat[wheat > 0] <- 0 #set non-NAs to zero
wheat <- wheat + wheat_lulc_mask #add wheat to land use fraction values
wheat[wheat == 0] <- NA #if land use fraction is zero set to NA
writeRaster(wheat, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_wheat_frac.nc", format="CDF",overwrite=T)

#soy
soy[soy > 0] <- 0 #set non-NAs to zero
soy <- soy + soy_lulc_mask #add wheat to land use fraction values
soy[soy == 0] <- NA #if land use fraction is zero set to NA
writeRaster(soy, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_soy_frac.nc", format="CDF",overwrite=T)

#maize
maize[maize > 0] <- 0 #set non-NAs to zero
maize <- maize + maize_lulc_mask #add wheat to land use fraction values
maize[maize == 0] <- NA #if land use fraction is zero set to NA
writeRaster(maize, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_maize_frac.nc", format="CDF",overwrite=T)

#agriculture
ag[ag > 0] <- 0 #set non-NAs to zero
ag <- ag + ag_lulc_mask #add wheat to land use fraction values
ag[ag == 0] <- NA #if land use fraction is zero set to NA
writeRaster(ag, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_ag_frac.nc", format="CDF",overwrite=T)

#ecological, where == 1
eco[eco > 0] <- 0 #set non-NAs to zero
eco <- eco + eco_lulc_mask #add wheat to land use fraction values
eco[eco == 0] <- NA #if land use fraction is zero set to NA
writeRaster(eco, filename = "/nfs/datadrivendroughteffect-data/Data/Masks/final_masks/NLDAS_monthly_eco_frac.nc", format="CDF",overwrite=T)



