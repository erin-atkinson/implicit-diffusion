using Oceananigans
using JLD2

# Unity length and time scales?
const L = 1
const T = 1

# Unity shear scale
# dU/dy = S
const S = 1

# 
const N = parse(Int, ARGS[1])
output_folder = "WENO-$N"
# Initial timestep
t = 0.1T / N

grid = RectilinearGrid(GPU();
    size=(N, N),
    extent=(L, L),
    topology=(Perioidic, Periodic, Flat)
)

# Initial conditions?
u(x, y) = 1e-8 * randn()
v(x, y) = 1e-8 * randn()

# Forcing with shear
@inline u_forcing_func(x, y, t, u, v)
@inline v_forcing_func(x, y, t, u, v)

model = NonhydrostaticModel(; grid
    advection=WENO(grid; order=5)
    forcing,
    closure=nothing,
)

simulation = Simulation(; model, stop_time=10T)

simulation.output_writers[:output] = JLD2OutputWriter()

simulation.callbacks[:wizard] = TimeStepWizard()
simulation.callbacks[:progress] = Callback()

run!(simulation)
