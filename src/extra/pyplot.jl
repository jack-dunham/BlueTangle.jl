# # Troubleshooting Plotting Issues

# If you encounter problems with plotting, please follow these steps:

# 1. **Install PyPlot in Julia**: Add the `PyPlot` package to your Julia environment. This package provides an interface to the `matplotlib` library in Python. You can install it using the Julia package manager:
#    ```julia
#    import Pkg
#    Pkg.add("PyPlot")
#    ```

# 2. **Install Python Matplotlib**: Ensure that `matplotlib` is installed in your Python environment. This is a prerequisite for `PyPlot` as it relies on Python's `matplotlib` for plotting. You can install `matplotlib` using `pip`:
#    ```bash
#    pip3 install matplotlib
#    ```

# For detailed documentation and additional information, refer to the [`PyPlot` GitHub page](https://github.com/JuliaPy/plt.jl).

using PyPlot

"""
`plot(sample_probs::Vector; rep::Symbol=:int, basis::String="Z")`

Plots the outcome probabilities for quantum measurements.

- `sample_probs`: Vector of tuples, each containing outcome probabilities and number of qubits.

Creates a bar plot showing the probabilities of the most likely outcomes in the specified measurement basis.
"""
function plotq(mVector::Vector{Measurement},labels::Vector{String}=[""])

    if length(mVector)>5
        throw("You can only plot five measurements.")
    end

    base_fig_width, base_fig_height = (7, 5)
    x_range = maximum([length(m.bitstr) for m=mVector])
    scale_factor = 0.5
    fig_width = base_fig_width + (x_range * scale_factor)
    fig_width = max(min(fig_width, 16), 5)

    fig, ax = subplots(figsize=(fig_width, base_fig_height),dpi=100)

    colors=["tab:blue","tab:orange","tab:green","tab:red","tab:purple","tab:brown"]

    for (i,r) = enumerate(mVector)

        x_outcome=r.bitstr
        y_sample=r.sample

        wid=.8/i

        lab=labels==[""] ? "($(i-1)) $(r.circuit_name)" : labels[i]
        bars=ax.bar(x_outcome, y_sample, wid, alpha=0.7, color=colors[i], label=lab)

            # Add the probabilities on top of each bar
        for bar in bars
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width() / 2., height + 0.005, string(round(height, digits=3)), 
                    ha="center", va="bottom", color=colors[i])
        end

        # ax.set_xticks(0:x_range)
    end

    # if rep==:bstr
        # ax.set_xlabel("Binary outcomes = left to right (first to last qubit)")
    # else
        ax.set_xlabel("Outcomes")
    # end

    ax.set_ylabel("Probabilities")
    ax.set_title("Outcome Probabilities")
    ax.grid(true)
    ax.legend()
    display(fig)

end

"""
`plot(m::Measurement; rep::Symbol=:int)`

Plots the outcome probabilities for a single quantum measurement.

- `m`: A Measurement object.

Creates a bar plot showing the probabilities of the most likely outcomes from the measurement.
"""
plotq(m::Measurement)=plotq([m])



## circuit drawing

_target_find(op::QuantumOps)=typeof(op)==ifOp ? -1 : op.target_qubit
_control_find(op::QuantumOps)=typeof(op)==ifOp ? -2 : op.control

"""
`_draw_gate(ax, op::QuantumOps, pos, gate_width)`

Internal function to draw a quantum gate on a circuit diagram.

- `ax`: The plot axis.
- `op`: The QuantumOps object representing the quantum operation.
- `pos`: Position on the circuit diagram.
- `gate_width`: Width of the gate drawing.

Draws the specified quantum gate on the given plot axis.
"""
function _draw_gate(ax, op::QuantumOps, pos, gate_width)
    qubit = op.qubit
    target_qubit = _target_find(op)
    control = _control_find(op)

    # symbol2=op.q==1 ? "o" : (BlueTangle._swap_control_target(op.mat)==op.mat ? "o" : "x")
    c="black"
    if op.type=="🔬" #op.noisy!=false
        c_t="red"
    else
        c_t="black"
    end


    if isa(op.mat,Function) #BlueTangle._clean_name(op.name) ∈ BlueTangle.gates_with_phase
        symbol2="o"
        c_t="blue"
    elseif op.q==1
        symbol2="o"
    else
        symbol2=BlueTangle._swap_control_target(op.mat)==op.mat ? "o" : "x"
    end

    if control != -2
        
        # Draw a line for the control-target connection
        ax.plot([pos, pos], [qubit - 1, control - 1], c)
        ax.plot(pos, control - 1, "o", color=c, markersize=gate_width*20)
 
        # Draw the control dot
        if op.q==1
            ax.plot(pos, qubit - 1, "x", color=c, markersize=gate_width*20)

            if control>qubit
                ax.text(pos, qubit - 1.4, "c-"*op.name, color=c_t, ha="center")
            else
                ax.text(pos, qubit - 0.7, "c-"*op.name, color=c_t, ha="center")
            end

        elseif op.q==2
            ax.plot(pos, qubit - 1, "o", color=c, markersize=gate_width*20)
            ax.plot(pos, target_qubit - 1, "x", color=c, markersize=gate_width*20)
            ax.plot([pos, pos], [qubit - 1, target_qubit - 1], c)

            ax.text(pos, target_qubit - .8, "c-"*op.name, color=c_t, ha="center")

        end

    # Single qubit gate
    elseif op.q == 1
        # Draw the gate symbol (e.g., a circle)

        if op.type=="🔬"
            ax.plot(pos, qubit - 1, marker=">", color=c, markersize=gate_width*30)
        else
            ax.plot(pos, qubit - 1, "o", color=c, markersize=gate_width*20)
        end
        # Add the gate name
        ax.text(pos, qubit - .7, op.name, color=c_t, ha="center", va="center")

    elseif op.q == 2
        # Draw a line for the control-target connection
        ax.plot([pos, pos], [qubit - 1, target_qubit - 1], c, markersize=gate_width*20)

        # Draw the control dot
        ax.plot(pos, qubit - 1, "o", color=c, markersize=gate_width*20)

        ax.plot(pos, target_qubit - 1, symbol2, color=c, markersize=gate_width*20)

        if target_qubit<qubit
            ax.text(pos, target_qubit - 1.4, op.name, color=c_t, ha="center")
        else
            ax.text(pos, target_qubit - 0.7, op.name, color=c_t, ha="center")
        end

    end

end

plotq(circuit::Circuit)=plotq(circuit.layers)

plotq(ansatz::AnsatzOptions)=plotq(ansatz.ops)

"""
`plot(ops::Vector{QuantumOps}; list_of_initial_qubits::Vector{Int}=Int[])`

Plots a quantum circuit diagram from a vector of quantum operations.

Creates a visual representation of the quantum circuit based on the specified operations and initial qubit states.
"""
function plotq(layers::Vector;list_of_initial_qubits::Vector{Int}=Int[])

    ops=vcat(layers...)
    
    if isempty(list_of_initial_qubits)
        qubit_lines = maximum([max(op.qubit, _target_find(op), _control_find(op)) for op in ops])
    else
        qubit_lines = length(list_of_initial_qubits)
    end

    num_ops = length(ops)
    num_layers = length(layers)
    println("layers=$(num_layers), ops=$(num_ops)")

    num=isa(layers,Vector{<:QuantumOps}) ? num_ops : num_layers

     # Adjust the xsize calculation
    xsize = num * 1.5  # Provide horizontal space based on number of operations
    ysize = qubit_lines * 1  # Vertical space based on qubit lines
    
    fig, ax = subplots(figsize=(xsize,ysize),dpi=100)#,tight_layout=true)
    ax.axis("off")  # Turn off the axis
    
    # Drawing constants
    gate_width = .4

    # Set plot limits
    ax.set_ylim(-1, qubit_lines)
    # ax.set_xlim(-0.5, num_ops)

    # Draw the horizontal lines for qubits and label them
    for i in 1:qubit_lines
        ax.hlines(i-1, -.5, num - 0.5, colors="black")#horizontal line
        label_text = list_of_initial_qubits == Int[] ? "Qubit $i" : "Qubit $i [$(list_of_initial_qubits[i])]"
        ax.text(-0.7, i-1, label_text, ha="right", va="center")
    end


    if isa(layers,Vector{<:QuantumOps})

        for (pos, op) in enumerate(ops)
            _draw_gate(ax, op, pos-1, gate_width)  # Position gates with some offset
        end

    else

        for (layer_idx, layer) in enumerate(layers)
            for op in layer
                _draw_gate(ax, op, layer_idx - 1, gate_width)  # Use layer_idx as horizontal position
            end
        end

    end

    display(fig)
end

"""
`savefigure(name::String)`
saves figure
"""
savefigure(name::String)=savefig(name)
