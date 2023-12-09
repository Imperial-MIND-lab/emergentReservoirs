#!/bin/bash
#PBS -l select=1:ncpus=12:mem=32gb
#PBS -l walltime=08:00:00
#PBS -N analysis01A
#PBS -J 1-10

module load tools/prod
module load MATLAB/2023a_Update_3

cd $PBS_O_WORKDIR

matlab -nodisplay -nosplash -nodesktop -r "try, run('~/projects/emergentReservoirs/main(${PBS_ARRAY_INDEX}).m'); catch me, e=getReport(me); fprintf('%s\n', e); end; exit;"
