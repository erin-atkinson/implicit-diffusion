using Oceananigans
using CUDA: @allowscalar

# Unity length and time scales?
const H = 1
const T = 1
const Q = 1

# Number of vertical cells
const N = parse(Int, ARGS[1])

const output_folder = joinpath(ARGS[2], "convection", "WENO-$N")

# Initial timestep
Δt = 0.01T / N

grid = RectilinearGrid(GPU();
    size=(2N, 2N, N),
    extent=(2H, 2H, H),
    topology=(Periodic, Periodic, Bounded)
)

# Initial conditions?
u(x, y, z) = 1e-8 * randn()
v(x, y, z) = 1e-8 * randn()
w(x, y, z) = 1e-8 * randn()

b_bcs = FieldBoundaryConditions(
    top = FluxBoundaryCondition(Q),
    bottom = FluxBoundaryCondition(Q)
)
boundary_conditions = (;
    b = b_bcs,
)

model = NonhydrostaticModel(; grid,
    advection=WENO(grid; order=5),
    boundary_conditions,
    buoyancy = BuoyancyTracer(),
    tracers=(:b, ),
    closure=nothing,
)
set!(model; u, v, w)

simulation = Simulation(model; stop_time=40T, Δt)

# Save kinetic and potential energy
TKE = (model.velocities.u^2 + model.velocities.v^2 + model.velocities.w^2) / 2

@inline PE_func(i, j, k, grid, b) = @inbounds -b[i, j, k] * grid.zᵃᵃᶜ[k]
bz = KernelFunctionOperation{Center, Center, Center}(PE_func, grid, model.tracers.b)
PE = Field(CumulativeIntegral(bz; dims=3)) # This defines z = -H as the zero for PE

!isdir(output_folder) && mkpath(output_folder)
simulation.output_writers[:output] = JLD2OutputWriter(model, 
    merge(model.velocities, model.tracers, (; TKE, PE)); 
    filename=joinpath(output_folder, "output.jld2"), 
    schedule=TimeInterval(T/10),
    overwrite_existing=true,
    with_halos=true
)

# Variable time step
wizard = TimeStepWizard(; cfl=0.4, max_Δt=T / N)
simulation.callbacks[:wizard] = Callback(wizard, IterationInterval(10))

function progress(sim)
    print("Running simulation t=$(round(time(sim); digits=2)) iter=$(iteration(sim))\r")
end
simulation.callbacks[:progress] = Callback(progress, IterationInterval(50))

run!(simulation)
