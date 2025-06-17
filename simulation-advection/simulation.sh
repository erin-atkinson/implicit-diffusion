#!/bin/bash
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --time=1:00:00
#SBATCH --job-name=WENO-3-64
#SBATCH --output=../scratch/logs/implicit-diffusion.WENO-3-64.txt
#module load cuda/11.7
module load julia/1.10.4
export JULIA_DEPOT_PATH=$SCRATCH/.julia-mist
export JULIA_SCRATCH_TRACK_ACCESS=0
cd ~/implicit-diffusion

output_path=$SCRATCH/implicit-diffusion
advection="Centered"
order="2"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="Centered"
order="4"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="Centered"
order="6"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="Centered"
order="8"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="WENO"
order="3"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="WENO"
order="5"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="WENO"
order="7"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path

output_path=$SCRATCH/implicit-diffusion
advection="WENO"
order="9"
N="64"

julia -t 8 -- simulation-advection/simulation.jl $advection $order $N $output_path
