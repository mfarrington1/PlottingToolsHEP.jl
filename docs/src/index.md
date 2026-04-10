# PlottingToolsHEP.jl

*A Julia package providing HEP-style plotting utilities built on CairoMakie and FHist.*

[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue?logo=julia)](https://mfarrington1.github.io/PlottingToolsHEP.jl/dev/)

## Features

- **ATLAS publication style** — one-line theme setup matching ATLAS experiment guidelines
- **1-D and 2-D histograms** — step histograms with error bars and heatmaps via [`plot_hist`](@ref)
- **Multi-histogram overlays** — stacked or overlaid plots with optional ratio and S/√B panels via [`multi_plot`](@ref)
- **Two-sample comparison** — overlaid pair with ratio panel via [`plot_comparison`](@ref)
- **Signal vs. background** — dedicated wrapper with cumulative S/√B significance panel via [`plot_signal_vs_background`](@ref)
- **Event displays** — 2-D (η, ϕ) displays for jets and leptons via [`event_display`](@ref)

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/mfarrington1/PlottingToolsHEP.jl")
```

## Quick Start

```julia
using PlottingToolsHEP, FHist, CairoMakie

h = Hist1D(randn(10_000); binedges = -6:0.1:6)
set_ATLAS_theme()

fig = plot_hist(h, "My distribution", L"$p_T$ [GeV]", "Events";
                options = HEPPlotOptions(ATLAS_label = "Internal", energy = 13.6))
```

See the [Usage](@ref usage) page for full worked examples and the [API Reference](@ref api-reference) page for complete docstrings.
