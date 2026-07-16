module PlottingToolsHEP
using Makie, CairoMakie
using ColorSchemes
using FHist
using LorentzVectorHEP
using MathTeXEngine

include("./PlottingObjects.jl")
export HEPPlotOptions
export gaudi_colors, ATLAS_colors, AtlasTheme, set_ATLAS_theme, add_ATLAS_internal!

include("./PlottingTools.jl")
export pdf_plot, plot_hist, plot_comparison, multi_plot, plot_signal_vs_background, plot_line

include("./ProjectionTools.jl")
export plot_hist_projections, interactive_projections

include("./EventDisplay.jl")
export event_display

end