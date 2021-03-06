#!/bin/bash
#SBATCH --job-name=D_maize_perc
#SBATCH --error=/nfs/datadrivendroughteffect-data/data_driven_drought/sbatch_logs/deficit_perc_maize_mask.err
#SBATCH --output=/nfs/datadrivendroughteffect-data/data_driven_drought/sbatch_logs/deficit_perc_maize_mask.out
#SBATCH --nodes=1
#SBATCH -p sesync

cd /nfs/datadrivendroughteffect-data/data_driven_drought/danielle/ 
R CMD BATCH --vanilla PRISM_masking_maize_deficit_percentiles.R R_out/PRISM_masking_maize_deficit_percentiles.Rout

