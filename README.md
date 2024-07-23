# Emergent Reservoirs
This repository contains code for replicating all analyses and figures of the corresponding preprint *Evolving reservoir computers reveals bidirectional coupling between predictive power and emergent dynamics* by Tolle et al., 2024.

# Installation
The code depends on the following external MATLAB packages:
- ReconcilingEmergences
- resampling_statistical_toolkit
- hhentschke-measures-of-effect-size-toolbox
- bluewhitered

Additionally, running this code requires editing the filepath of the directory where external dependencies are stored in `addPaths.m` (line 30).

To run a test run (with significantly reduced number of repetitions etc.) of all analyses, simply execute `run_all.m`. This takes about 10-15 min on a standard laptop and will add the required search paths, execute all analyses, produce all plots and save outputs and figures. The same script can also be used to run all analyses with the original configurations as used in the published preprint by setting `testRun=false`. However, we strongly recommended to run the different analyses in parallel, making use of the `jobID` parameter in `main.m`.

# Citation
If you use this code in your research, kindly cite: Tolle, et al. (2024) Evolving reservoir computers reveals bidirectional coupling between predictive power and emergent dynamics. arXiv.
