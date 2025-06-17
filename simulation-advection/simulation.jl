using Oceananigans
using CUDA: @allowscalar

# Unity length and time scales?
const L = 1
const T = 1

# Velocity
const c = 1


const order = parse(Int, ARGS[2])
const N = parse(Int, ARGS[3])
const output_folder = joinpath(ARGS[4], "advection", "$(ARGS[1])-$order-$N")
# Distribution width
const σ = 2L / N

# Initial timestep
Δt = 0.01T / N

grid = RectilinearGrid(GPU();
    size=(N, ),
    extent=(L, ),
    topology=(Periodic, Flat, Flat),
    halo=(5,)
)

const advection = ARGS[1] == "WENO" ? WENO(grid; order) :
                  ARGS[1] == "Centered" ? Centered(grid; order) :
                  @error "Not a valid advection scheme"

model = NonhydrostaticModel(; grid,
    advection,
    tracers=(:ψ, ),
    closure=nothing,
)
set!(model; u=c, ψ=x->exp(-(x - L/2)^2 / 2σ^2))

simulation = Simulation(model; stop_time=50T, Δt)

!isdir(output_folder) && mkpath(output_folder)
simulation.output_writers[:output] = JLD2OutputWriter(model, 
    (; model.tracers.ψ); 
    filename=joinpath(output_folder, "output.jld2"), 
    schedule=TimeInterval(T/20),
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
