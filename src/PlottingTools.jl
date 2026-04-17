# ── internal helper ──────────────────────────────────────────────────────────

# Add a statistics box to a figure layout cell.
function statbox!(fig, hist::Hist1D; position=(1, 2))
    bc      = bincounts(hist)
    centers = bincenters(hist)
    n  = sum(bc)
    μ  = n > 0 ? mean(hist) : 0.0
    σ  = n > 0 ? std(hist) : 0.0
    stats = "Entries: $(Int(round(n)))\nMean: $(round(μ, digits=4))\nStd Dev: $(round(σ, digits=4))"
    Label(fig[position...], stats; tellwidth=false, justification=:left)
end

function statbox!(fig, hist::Hist2D; position=(1, 2))
    n = sum(bincounts(hist))
    Label(fig[position...], "Entries: $(Int(round(n)))"; tellwidth=false, justification=:left)
end


"""
    plot_hist(hist, title, xlabel, ylabel;
              label=nothing, normalize_hist=false,
              colticks=Makie.automatic, colorbar_label="",
              colorscale=identity, colorrange=Makie.automatic,
              options=HEPPlotOptions())

Plot a single `Hist1D` or `Hist2D` and return the `Figure`.

`Hist2D` entries are displayed as heatmaps with a colour bar; use `colticks`,
`colorbar_label`, `colorscale`, and `colorrange` to control it.
Common axis options (scale, ticks, limits, ATLAS label) are bundled in `options`.
"""
function plot_hist(hist, title, xlabel, ylabel;
                   label=nothing, normalize_hist=false,
                   colticks=Makie.automatic, colorbar_label="",
                   colorscale=identity, colorrange=Makie.automatic,
                   options=HEPPlotOptions())

    CairoMakie.activate!(type="png")
    fig = CairoMakie.Figure()
    hist_norm = normalize_hist ? normalize(hist) : hist

    if hist isa Hist1D
        limits = options.limits === (nothing, nothing) ?
            ((minimum(binedges(hist_norm)), maximum(binedges(hist_norm))),
             (0, 1.05 * maximum(bincounts(hist_norm)))) :
            options.limits
        ax = CairoMakie.Axis(fig[1, 1]; xlabel, ylabel, title,
                              xscale=options.xscale, yscale=options.yscale,
                              xticks=options.xticks, yticks=options.yticks,
                              limits)
        CairoMakie.stephist!(ax, hist_norm; label)
        CairoMakie.errorbars!(ax, hist_norm; whiskerwidth=6)
        label !== nothing && CairoMakie.axislegend()

    elseif hist isa Hist2D
        limits = options.limits === (nothing, nothing) ?
            ((minimum(binedges(hist_norm)[1]), maximum(binedges(hist_norm)[1])),
             (minimum(binedges(hist_norm)[2]), maximum(binedges(hist_norm)[2]))) :
            options.limits
        ax, hm = CairoMakie.heatmap(fig[1, 1], hist_norm;
                     axis=(; title, xlabel, ylabel,
                             xscale=options.xscale, yscale=options.yscale,
                             xticks=options.xticks, yticks=options.yticks,
                             limits),
                     colorscale, colorrange)
        CairoMakie.Colorbar(fig[1, 2], hm; label=colorbar_label, ticks=colticks)
    end

    if options.ATLAS_label !== nothing
        add_ATLAS_internal!(ax, options.ATLAS_label;
                            offset=options.ATLAS_label_offset, energy=options.energy)
    end

    CairoMakie.current_figure()
end

"""
    multi_plot(hists, title, xlabel, ylabel, hist_labels;
               signal_hists=nothing, signal_labels=String[],
               data_hist=nothing, data_hist_style="scatter", data_label="Data",
               normalize_hists="", stack=false,
               lower_panel=:none, ratio_label="Data/MC",
               plot_errors=true, color=ATLAS_colors,
               legend_position=:inside,
               legend_align=(valign=0.95, halign=0.95),
               options=HEPPlotOptions())

Overlay multiple histograms on one axis and return the `Figure`.

- `normalize_hists`: `""` (none), `"individual"` (each normalized to 1), or
  `"total"` (all scaled to a common integral).
- `stack`: if `true`, draw background histograms as a stacked histogram using `stackedhist!`.
- `signal_hists` / `signal_labels`: optional second group drawn with dashed lines and
  individually normalised when `normalize_hists="total"`. When provided, the legend is
  placed to the side unless `legend_position=:inside`.
- `data_hist`: optional data histogram drawn on top in black.
- `lower_panel`: controls the sub-panel drawn below the main axis:
  - `:none` – no sub-panel (default)
  - `:ratio` – Data/MC ratio panel (requires `data_hist`); label set by `ratio_label`
  - `:s_sqrt_b` – cumulative S/√B panel (requires `signal_hists`)
- `color`: vector of colours matched to `hist_labels` (default: `ATLAS_colors`).
- `legend_position`: `:inside` (default, overlaid on axis) or `:side` (fig[1,2]).
"""
function multi_plot(hists, title, xlabel, ylabel, hist_labels;
                    signal_hists=nothing, signal_labels=String[],
                    data_hist=nothing, data_hist_style="scatter", data_label="Data",
                    normalize_hists="", stack=false,
                    lower_panel=:none, ratio_label="Data/MC",
                    plot_errors=true, color=ATLAS_colors,
                    legend_position=:inside,
                    legend_align=(valign=0.95, halign=0.95),
                    options=HEPPlotOptions())

    CairoMakie.activate!(type="png")
    fig    = CairoMakie.Figure()
    limits = options.limits === (nothing, nothing) ?
        ((minimum(binedges(hists[1])), maximum(binedges(hists[1]))),
         (0, 1.05 * maximum(bincounts(sum(hists))))) :
        options.limits
    ax = CairoMakie.Axis(fig[1, 1]; xlabel, ylabel, title,
                         yscale=options.yscale, limits,
                         xticks=options.xticks, yticks=options.yticks)

    # ── normalise background/main histograms ──────────────────────────────────
    if normalize_hists == "individual"
        norm_hists = [normalize(h) for h in hists]
    elseif normalize_hists == "total"
        tot_integral = sum(integral(h) for h in hists)
        norm_hists   = [h * (1 / tot_integral) for h in hists]
    else
        norm_hists = hists
    end

    # ── draw main histograms ──────────────────────────────────────────────────
    if stack
        stackedhist!(ax, norm_hists; color, errorcolor=(:white, 0.0))
        elements = Any[PolyElement(polycolor=color[i]) for i in 1:length(hist_labels)]
    else
        for (i, hist) in enumerate(norm_hists)
            CairoMakie.stephist!(ax, hist; clamp_bincounts=true, color=color[i])
            plot_errors && CairoMakie.errorbars!(ax, hist; whiskerwidth=6, clamp_errors=true, color=color[i])
        end
        elements = Any[LineElement(linecolor=color[i]) for i in 1:length(hist_labels)]
    end

    # ── draw signal histograms (dashed) ───────────────────────────────────────
    norm_signal_hists = nothing
    if signal_hists !== nothing
        norm_signal_hists = normalize_hists != "" ?
            [normalize(h) for h in signal_hists] : signal_hists
        n_main = length(hist_labels)
        for (i, hist) in enumerate(norm_signal_hists)
            c = color[mod1(n_main + i, length(color))]
            CairoMakie.stephist!(ax, hist; clamp_bincounts=true, color=c, linestyle=:dash)
            push!(elements, LineElement(linecolor=c, linestyle=:dash))
        end
    end

    # ── draw data histogram ───────────────────────────────────────────────────
    all_labels = vcat(hist_labels, signal_hists !== nothing ? signal_labels : String[])
    if data_hist !== nothing
        data_hist_norm = (normalize_hists in ("individual", "total")) ?
            normalize(data_hist) : data_hist
        if data_hist_style == "scatter"
            CairoMakie.scatter!(ax, data_hist_norm; color=:black)
            elements = vcat(elements, MarkerElement(marker=:circle, markercolor=:black))
        elseif data_hist_style == "stephist"
            CairoMakie.stephist!(ax, data_hist_norm; color=:black)
            elements = vcat(elements, LineElement(linecolor=:black))
        end
        push!(all_labels, data_label)
    end

    # ── legend ────────────────────────────────────────────────────────────────
    if legend_position === :side
        Legend(fig[1, 2], elements, all_labels, "Legend")
    else
        Legend(fig[1, 1], elements, all_labels;
               tellheight=false, tellwidth=false,
               valign=legend_align.valign, halign=legend_align.halign)
    end

    # ── lower panel ───────────────────────────────────────────────────────────
    if lower_panel === :ratio && data_hist !== nothing
        data_hist_norm = (normalize_hists in ("individual", "total")) ?
            normalize(data_hist) : data_hist
        CairoMakie.errorbars!(ax, data_hist; whiskerwidth=6, clamp_errors=true, color=:black)
        ratioax = CairoMakie.Axis(fig[2, 1]; xlabel, ylabel=ratio_label, tellwidth=true)
        FHist.ratiohist!(ratioax, data_hist_norm / sum(norm_hists);
                         color=CairoMakie.Makie.wong_colors()[2])
        CairoMakie.ylims!(ratioax, 0.5, 1.5)
        CairoMakie.linkxaxes!(ratioax, ax)
        CairoMakie.hidexdecorations!(ax; minorticks=false, ticks=false)
        CairoMakie.rowsize!(fig.layout, 2, CairoMakie.Makie.Relative(1 / 6))

    elseif lower_panel === :s_sqrt_b && norm_signal_hists !== nothing
        ratioax = CairoMakie.Axis(fig[2, 1]; xlabel,
                                  ylabel=L"\fontfamily{TeXGyreHeros} S / \sqrt{B}",
                                  tellwidth=true)
        signal_counts = reduce(.+, bincounts(h) for h in norm_signal_hists)
        bkg_counts    = reduce(.+, bincounts(h) for h in norm_hists)
        centers       = bincenters(norm_signal_hists[1])
        edges         = binedges(norm_signal_hists[1])
        sig_values    = [sum(signal_counts[i:end]) / sqrt(max(sum(bkg_counts[i:end]), 1e-10))
                         for i in eachindex(centers)]
        CairoMakie.stairs!(ratioax, collect(edges), vcat(sig_values, sig_values[end]);
                           color=CairoMakie.Makie.wong_colors()[2])
        CairoMakie.linkxaxes!(ratioax, ax)
        CairoMakie.hidexdecorations!(ax; minorticks=false, ticks=false)
        CairoMakie.rowsize!(fig.layout, 2, CairoMakie.Makie.Relative(1 / 5))
    end

    if options.ATLAS_label !== nothing
        add_ATLAS_internal!(ax, options.ATLAS_label;
                            energy=options.energy, offset=options.ATLAS_label_offset)
    end

    CairoMakie.current_figure()
end

"""
    plot_comparison(hist1, hist2, title, xlabel, ylabel,
                    hist1_label, hist2_label, comp_label;
                    normalize_hists=true, plot_as_data=[false, false],
                    options=HEPPlotOptions())

Plot two histograms overlaid with a ratio panel below and return the `Figure`.

Set `plot_as_data[i] = true` to draw the i-th histogram as scatter points instead
of a step histogram.

!!! note
    This is a convenience wrapper around [`multi_plot`](@ref). For more control
    (stacking, signal overlay, S/√B panel) use `multi_plot` directly.
"""
function plot_comparison(hist1, hist2, title, xlabel, ylabel,
                         hist1_label, hist2_label, comp_label;
                         normalize_hists=true, plot_as_data=[false, false],
                         options=HEPPlotOptions())
    norm = normalize_hists ? "individual" : ""
    style2 = plot_as_data[2] ? "scatter" : "stephist"
    # hist1 is the reference; hist2 is treated as the "data" overlay so the
    # ratio panel shows hist2/hist1 (equivalent to data/MC with one MC sample).
    multi_plot([hist1], title, xlabel, ylabel, [hist1_label];
               data_hist=hist2, data_hist_style=style2, data_label=hist2_label,
               normalize_hists=norm,
               plot_errors=true,
               lower_panel=:ratio, ratio_label=comp_label,
               options=options)
end

"""
    plot_signal_vs_background(signal_hists, bkg_hists, title, xlabel, ylabel,
                              signal_labels, bkg_labels;
                              normalize_hists="", stack=false,
                              plot_s_sqrt_b=true, color=ATLAS_colors,
                              options=HEPPlotOptions())

Plot signal and background histograms overlaid, optionally with a cumulative
S/√B significance panel below, and return the `Figure`.

!!! note
    This is a convenience wrapper around [`multi_plot`](@ref). For more control
    use `multi_plot` directly with `signal_hists`, `lower_panel=:s_sqrt_b`, and
    `legend_position=:side`.
"""
function plot_signal_vs_background(signal_hists, bkg_hists, title, xlabel, ylabel,
                                   signal_labels, bkg_labels;
                                   normalize_hists="", stack=false,
                                   plot_s_sqrt_b=true,
                                   color=ATLAS_colors,
                                   options=HEPPlotOptions())
    multi_plot(bkg_hists, title, xlabel, ylabel, bkg_labels;
               signal_hists, signal_labels,
               normalize_hists, stack,
               lower_panel=plot_s_sqrt_b ? :s_sqrt_b : :none,
               plot_errors=true, color,
               legend_position=:side,
               options=options)
end
