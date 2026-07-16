# ── 2D projection explorer ────────────────────────────────────────────────────

# Explicit step-outline path for a histogram slice, drawn with `lines!` so the
# same code serves the horizontal (top) and vertical (right) projection panels.
function _steppath(edges, values; vertical=false)
    pts = Makie.Point2f[]
    for i in eachindex(values)
        for e in (edges[i], edges[i+1])
            push!(pts, vertical ? Makie.Point2f(values[i], e) : Makie.Point2f(e, values[i]))
        end
    end
    pts
end

# Build the heatmap + marginal-projection layout. Returns `(fig, ax, update!)`
# where `update!(x, y)` moves the crosshair to the data point `(x, y)` and
# refreshes both projection panels. Uses only the generic Makie API and never
# activates a backend, so it works under CairoMakie, GLMakie, and WGLMakie.
function _projection_figure(hist, title, xlabel, ylabel;
                            window_bins=1, colorbar_label="",
                            colticks=Makie.automatic,
                            colorscale=identity, colorrange=Makie.automatic,
                            options=HEPPlotOptions())
    h2d            = _to_hist2d(hist)
    counts         = bincounts(h2d)
    xedges, yedges = binedges(h2d)
    nx, ny         = size(counts)

    limits = options.limits === (nothing, nothing) ?
        ((first(xedges), last(xedges)), (first(yedges), last(yedges))) :
        options.limits

    fig = Makie.Figure()
    ax  = Makie.Axis(fig[2, 1]; xlabel, ylabel,
                     xscale=options.xscale, yscale=options.yscale,
                     xticks=options.xticks, yticks=options.yticks, limits)
    hm  = Makie.heatmap!(ax, h2d; colorscale, colorrange)

    ax_x = Makie.Axis(fig[1, 1]; ylabel="Events", title)
    ax_y = Makie.Axis(fig[2, 2]; xlabel="Events")
    Makie.Colorbar(fig[2, 3], hm; label=colorbar_label, ticks=colticks)
    Makie.linkxaxes!(ax, ax_x)
    Makie.linkyaxes!(ax, ax_y)
    Makie.hidexdecorations!(ax_x; ticks=false, minorticks=false, grid=false)
    Makie.hideydecorations!(ax_y; ticks=false, minorticks=false, grid=false)
    Makie.rowsize!(fig.layout, 1, Makie.Relative(1 / 4))
    Makie.colsize!(fig.layout, 2, Makie.Relative(1 / 4))

    xpath   = Makie.Observable(_steppath(xedges, zeros(nx)))
    ypath   = Makie.Observable(_steppath(yedges, zeros(ny); vertical=true))
    cross_x = Makie.Observable(0.0)
    cross_y = Makie.Observable(0.0)
    Makie.lines!(ax_x, xpath; color=ATLAS_colors[1])
    Makie.lines!(ax_y, ypath; color=ATLAS_colors[1])
    Makie.vlines!(ax, cross_x; color=:red, linewidth=1)
    Makie.hlines!(ax, cross_y; color=:red, linewidth=1)

    half = max(window_bins - 1, 0) ÷ 2
    function update!(x, y)
        i = clamp(searchsortedlast(xedges, x), 1, nx)
        j = clamp(searchsortedlast(yedges, y), 1, ny)
        xvals = vec(sum(counts[:, max(j - half, 1):min(j + half, ny)]; dims=2))
        yvals = vec(sum(counts[max(i - half, 1):min(i + half, nx), :]; dims=1))
        xpath[]   = _steppath(xedges, xvals)
        ypath[]   = _steppath(yedges, yvals; vertical=true)
        cross_x[] = clamp(x, first(xedges), last(xedges))
        cross_y[] = clamp(y, first(yedges), last(yedges))
        Makie.ylims!(ax_x, 0, 1.05 * max(maximum(xvals), 1))
        Makie.xlims!(ax_y, 0, 1.05 * max(maximum(yvals), 1))
        nothing
    end
    update!((first(xedges) + last(xedges)) / 2, (first(yedges) + last(yedges)) / 2)

    if options.ATLAS_label !== nothing
        add_ATLAS_internal!(ax, options.ATLAS_label;
                            offset=options.ATLAS_label_offset, energy=options.energy)
    end

    fig, ax, update!
end

"""
    plot_hist_projections(hist, x, y, title, xlabel, ylabel;
                          window_bins=1, colorbar_label="",
                          colticks=Makie.automatic,
                          colorscale=identity, colorrange=Makie.automatic,
                          options=HEPPlotOptions())

Plot a `Hist2D` as a heatmap with its x and y projections at the point `(x, y)`
and return the `Figure`.

The x projection (top panel) is the slice of the histogram along x at the y bin
containing `y`; the y projection (right panel) is the slice along y at the x bin
containing `x`. A crosshair marks the chosen point. Set `window_bins=n` (odd) to
sum the slice over `n` bins centred on the cursor bin instead of a single bin.
Points outside the histogram range are clamped to the nearest bin.

`hist` may be a `Hist2D` or a 3-tuple `(counts_matrix, xedges, yedges)`, so
NumPy arrays can be passed directly from Python via juliacall.

For a cursor-driven version see [`interactive_projections`](@ref).
"""
function plot_hist_projections(hist, x, y, title, xlabel, ylabel;
                               window_bins=1, colorbar_label="",
                               colticks=Makie.automatic,
                               colorscale=identity, colorrange=Makie.automatic,
                               options=HEPPlotOptions())
    CairoMakie.activate!(type="png")
    fig, _, update! = _projection_figure(hist, title, xlabel, ylabel;
                                         window_bins, colorbar_label, colticks,
                                         colorscale, colorrange, options)
    update!(x, y)
    fig
end

"""
    interactive_projections(hist, title, xlabel, ylabel;
                            window_bins=1, colorbar_label="",
                            colticks=Makie.automatic,
                            colorscale=identity, colorrange=Makie.automatic,
                            options=HEPPlotOptions())

Like [`plot_hist_projections`](@ref), but the projection point follows the mouse
cursor: moving the mouse over the heatmap updates the crosshair and both
projection panels live.

This function does **not** activate a backend — interactivity requires one that
handles mouse events, so activate GLMakie or WGLMakie before displaying.

Over SSH (e.g. VS Code Remote-SSH) use WGLMakie. On a headless node
`display(fig)` starts a local web server but cannot open a browser, so nothing
appears on its own — fix the server port and open the page yourself:

```julia
using WGLMakie, Bonito
fig = interactive_projections(h2d, "", "x", "y")
display(fig)
```

If trying to render from the VS Code Julia REPL, you must use
```julia
WGLMakie.activate!(inline=false)
```
for the plot to render correctly. 
"""
function interactive_projections(hist, title, xlabel, ylabel;
                                 window_bins=1, colorbar_label="",
                                 colticks=Makie.automatic,
                                 colorscale=identity, colorrange=Makie.automatic,
                                 options=HEPPlotOptions())
    backend = Makie.current_backend()
    if backend === missing || nameof(backend) === :CairoMakie
        @warn "CairoMakie is the active backend, so this figure will be static. " *
              "Interactivity needs WGLMakie or GLMakie: call `WGLMakie.activate!()` " *
              "and re-create the figure. (The most recently loaded backend wins, " *
              "so activate explicitly rather than relying on load order.)"
    end
    fig, ax, update! = _projection_figure(hist, title, xlabel, ylabel;
                                          window_bins, colorbar_label, colticks,
                                          colorscale, colorrange, options)
    mousepos = Makie.Observables.throttle(0.03, Makie.events(fig).mouseposition)
    Makie.on(mousepos) do _
        if Makie.is_mouseinside(ax.scene)
            pos = Makie.mouseposition(ax.scene)
            update!(pos[1], pos[2])
        end
    end
    fig
end
