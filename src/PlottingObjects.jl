"""
    HEPPlotOptions(; kwargs...)

Common axis and labelling options shared across HEP plotting functions.

# Fields
- `yscale`: Y-axis scale function (default: `identity`)
- `xscale`: X-axis scale function (default: `identity`)
- `xticks`: X-axis tick specification (default: `Makie.automatic`)
- `yticks`: Y-axis tick specification (default: `Makie.automatic`)
- `limits`: Axis limits `((xmin, xmax), (ymin, ymax))`, or `(nothing, nothing)` for automatic
- `ATLAS_label`: Secondary text placed after "ATLAS" (e.g. `"Internal"`), or `nothing` to suppress
- `ATLAS_label_offset`: Pixel offset of the ATLAS label from the top-left corner (default: `(30, -20)`)
- `energy`: Centre-of-mass energy in TeV shown in the ATLAS label (default: `13.6`)

# Example
```julia
opts = HEPPlotOptions(ATLAS_label="Internal", energy=14.0, limits=((-5, 5), (0, 200)))
plot_hist(h, "My Plot", "x [GeV]", "Events"; options=opts)
```
"""
Base.@kwdef struct HEPPlotOptions
    yscale             = identity
    xscale             = identity
    xticks             = Makie.automatic
    yticks             = Makie.automatic
    limits             = (nothing, nothing)
    ATLAS_label::Union{Nothing,String} = nothing
    ATLAS_label_offset = (30, -20)
    energy::Float64    = 13.6
end

gaudi_colors = ["#cb181d", "#fa6a4a", "#2271b5", "#bdd7e7", "#238b21", "#a1cf42",
                "#ff8c00", "#fee147"]

ATLAS_colors = ["#3f90da", "#ffa912", "#bd2001", "#94a4a2", "#842db6", "#e76400", "#717581",
                "#92dadd", "#a96b59"]

"""
    set_ATLAS_theme()

Set the global Makie theme to the ATLAS experiment publication style.
"""
function set_ATLAS_theme()
    set_texfont_family!(FontFamily("TeXGyreHeros"))
    set_theme!(AtlasTheme())
end

"""
    AtlasTheme()

Return a Makie `Theme` styled after the ATLAS experiment's publication guidelines.
"""
AtlasTheme() = return Theme(
    fonts = Attributes(:regular => "Nimbus", :bold => "Nimbus Bold", :italic => "Nimbus Italic", :bolditalic => "Nimbus Bold Italic"),
    Axis=(
        xtickalign=1, ytickalign=1,
        xticksmirrored=1, yticksmirrored=1,
        xminortickalign=1, yminortickalign=1,
        xticksize=10, yticksize=15,
        xminorticksize=5, yminorticksize=8,
        xgridvisible=false, ygridvisible=false,
        xminorticksvisible=true, yminorticksvisible=true,
        xminorticks=IntervalsBetween(5),
        yminorticks=IntervalsBetween(5),
    ),
    Colorbar=(
        colormap=:haline,
        highclip=:red,
        lowclip=:black,
    ),
    Legend=(
        framevisible=false,
    ),
)

"""
    add_ATLAS_internal!(ax, sec_text; offset=(250, -20), fontsize=20, energy=13.6)

Overlay the standard ATLAS label and centre-of-mass energy annotation onto axis `ax`.
`sec_text` is the secondary descriptor placed after "ATLAS", e.g. `"Internal"` or
`"Simulation"`.
"""
function add_ATLAS_internal!(ax, sec_text; offset=(250, -20), fontsize=20, energy=13.6)
    text!(ax, 0, 1;
        text=rich(rich("ATLAS  "; font="Nimbus Bold Italic", fontsize),
                  rich(sec_text; font="Nimbus", fontsize=(fontsize - 1))),
        align=(:left, :top), offset, space=:relative,
    )
    text!(ax, 0, 1;
        text=L"\fontfamily{NewComputerModern}\mathbf{\sqrt{s}}",
        align=(:left, :top), offset=(offset[1], offset[2] - 30),
        space=:relative, fontsize=15,
    )
    text!(ax, 0, 1;
        text=" = " * string(energy) * " TeV",
        align=(:left, :top), offset=(offset[1] + 25, offset[2] - 30),
        space=:relative, fontsize=15,
    )
    nothing
end