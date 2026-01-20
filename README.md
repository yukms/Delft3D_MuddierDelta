DOI Updated : 10.5281/zenodo.18319314

This repository contains MATLAB codes and data for analyzing sediment retention processes in river deltas using numerical modeling and field data comparisons.

## Overview

This research investigates sediment retention mechanisms in deltaic environments through Delft3D numerical modeling and field data analysis. The code processes model outputs, analyzes sediment transport patterns, and generates figures.

## Repository Structure

### Data Files
- **`FieldDelta.xlsx`** - Field data from delta environments
- **`FieldSaito.xlsx`** - Field data from Saito et al. study
- **`R29.mat`**, **`R30.mat`**, **`R31.mat`**, **`R32.mat`** - Model simulation results for runs 29-32
- **`estimate_D50_from_bedsus_ratio.m`** - Script to estimate median grain size from bed/suspended sediment ratios

### Model Setup
**`Delft3D Model setup/`**
- **`Run29/`** - Complete Delft3D model configuration and setup files
  - `advectionlength.m` - Calculate sediment advection length
  - `DATA_EXT.m` - Extract and process model output data
  - `OAM_delta.m` - Delta analysis script
  - `run_series_of_models.m` - Batch script to run multiple simulations
  - **`[Cohesive_Mud_Included] Retention_input/`** - Model input files including:
    - Grid files (`.grd`, `.enc`)
    - Bathymetry (`.dep`)
    - Boundary conditions (`.bcc`, `.bct`, `.bnd`)
    - Sediment parameters (`.sed`)
    - Morphological settings (`.mor`)
    - Main model definition file (`.mdf`)

### Figure Generation Scripts
- **`Figure1_Delta evolution/`** - Scripts for visualizing delta morphological evolution
  - `Figure1.m` - Main figure generation script
  - `forfig1.mat` - Processed data for Figure 1

- **`Figure2_Sediment retention/`** - Sediment retention analysis
  - `Figure2_Astar_sedimentretention.m` - A-star sediment retention analysis
  - `Figure2_Boxplot.m` - Statistical box plot generation

- **`Figure3_Advection length/`** - Advection length analysis
  - `Figure3_advectionlength.m` - Advection length calculations
  - `Figure3_deltaradius.m` - Delta radius analysis
  - `Run_29/`, `Run_30/`, `Run_31/`, `Run_32/` - Processed advection length data for each model run

- **`Figure4_Total retention/`**
  - `Figure4_Total_retention.m` - Total sediment retention analysis

- **`Figure5_Muddier delta/`**
  - `Figure5_Muddier_delta.m` - Analysis of mud-rich delta systems

- **`SupplementaryFigures/`** - Additional supporting figures
  - `Supplementary_Fig1.m` through `Supplementary_Fig4.m`
  - `Supplementary_Fig5/` - Includes log data analysis
  - `Supplementary_Fig6/` - Field data D50 estimation



