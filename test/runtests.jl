using Test
using PlottingToolsHEP
using CairoMakie
using FHist
using Random

Random.seed!(42)

# Use the non-display backend so tests can run headlessly.
CairoMakie.activate!(type="png")

@testset "PlottingToolsHEP" begin

    h1 = Hist1D(randn(1000); binedges=-6:0.1:6)
    h2 = Hist1D(2 .* randn(1000); binedges=-6:0.1:6)
    h3 = Hist1D(randn(1000) .+ 1; binedges=-6:0.1:6)
    h4 = Hist2D((randn(1000), randn(1000)))

    # Pre-binned tuple data for Python-interop tests
    counts_1d = Float64.(rand(1:50, 120))
    edges_1d  = collect(range(-6.0, 6.0; length=121))
    counts_2d = Float64.(rand(1:10, 20, 20))
    xedges_2d = collect(range(-4.0, 4.0; length=21))
    yedges_2d = collect(range(-4.0, 4.0; length=21))

    # ── HEPPlotOptions ───────────────────────────────────────────────────────

    @testset "HEPPlotOptions defaults" begin
        opts = HEPPlotOptions()
        @test opts.energy == 13.6
        @test opts.ATLAS_label === nothing
        @test opts.yscale === identity
    end

    @testset "HEPPlotOptions keyword construction" begin
        opts = HEPPlotOptions(energy=14.0, ATLAS_label="Internal")
        @test opts.energy == 14.0
        @test opts.ATLAS_label == "Internal"
    end

    # ── plot_hist ────────────────────────────────────────────────────────────

    @testset "plot_hist Hist1D" begin
        fig = plot_hist(h1, "Test", "x", "y")
        @test fig isa Makie.Figure
    end

    @testset "plot_hist Hist1D normalized" begin
        fig = plot_hist(h1, "Test", "x", "y"; normalize_hist=true)
        @test fig isa Makie.Figure
    end

    @testset "plot_hist Hist1D with options" begin
        opts = HEPPlotOptions(ATLAS_label="Internal", energy=13.0,
                              limits=((-6.0, 6.0), (0.0, 500.0)))
        fig = plot_hist(h1, "Test", "x", "y"; options=opts)
        @test fig isa Makie.Figure
    end

    @testset "plot_hist Hist2D" begin
        fig = plot_hist(h4, "2D Test", "x", "y")
        @test fig isa Makie.Figure
    end

    # ── plot_comparison ──────────────────────────────────────────────────────

    @testset "plot_comparison" begin
        fig = plot_comparison(h1, h2, "Test", "x", "y", "h1", "h2", "h2/h1")
        @test fig isa Makie.Figure
    end

    @testset "plot_comparison with ATLAS label" begin
        opts = HEPPlotOptions(ATLAS_label="Internal", energy=14.0)
        fig = plot_comparison(h1, h2, "Test", "x", "y", "h1", "h2", "h2/h1";
                              options=opts)
        @test fig isa Makie.Figure
    end

    # ── multi_plot ───────────────────────────────────────────────────────────

    @testset "multi_plot unstacked" begin
        fig = multi_plot([h1, h2, h3], "Test", "x", "y", ["h1", "h2", "h3"])
        @test fig isa Makie.Figure
    end

    @testset "multi_plot stacked" begin
        fig = multi_plot([h1, h2], "Test", "x", "y", ["h1", "h2"]; stack=true)
        @test fig isa Makie.Figure
    end

    @testset "multi_plot with data overlay" begin
        fig = multi_plot([h1, h2], "Test", "x", "y", ["h1", "h2"];
                         data_hist=h3, data_label="Data")
        @test fig isa Makie.Figure
    end

    # ── plot_signal_vs_background ────────────────────────────────────────────

    @testset "plot_signal_vs_background" begin
        fig = plot_signal_vs_background(
            [h3], [h1, h2], "Test", "x", "y",
            ["Signal"], ["Bkg 1", "Bkg 2"])
        @test fig isa Makie.Figure
    end

    @testset "plot_signal_vs_background stacked" begin
        fig = plot_signal_vs_background(
            [h3], [h1, h2], "Test", "x", "y",
            ["Signal"], ["Bkg 1", "Bkg 2"];
            stack=true, normalize_hists="total")
        @test fig isa Makie.Figure
    end

    # ── Python interop: tuple inputs and string kwargs ───────────────────────

    @testset "plot_hist from tuple (1D)" begin
        fig = plot_hist((counts_1d, edges_1d), "Tuple 1D", "x", "Events")
        @test fig isa Makie.Figure
    end

    @testset "plot_hist from tuple (2D)" begin
        fig = plot_hist((counts_2d, xedges_2d, yedges_2d), "Tuple 2D", "x", "y")
        @test fig isa Makie.Figure
    end

    @testset "multi_plot from tuples" begin
        fig = multi_plot([(counts_1d, edges_1d), (counts_1d .* 0.8, edges_1d)],
                         "Tuples", "x", "Events", ["A", "B"])
        @test fig isa Makie.Figure
    end

    @testset "multi_plot string lower_panel" begin
        fig = multi_plot([h1, h2], "Test", "x", "y", ["h1", "h2"];
                         data_hist=h3, lower_panel="ratio")
        @test fig isa Makie.Figure
    end

    @testset "multi_plot string legend_position" begin
        fig = multi_plot([h1, h2], "Test", "x", "y", ["h1", "h2"];
                         legend_position="side")
        @test fig isa Makie.Figure
    end

    @testset "plot_comparison from tuples" begin
        fig = plot_comparison((counts_1d, edges_1d), (counts_1d .* 1.1, edges_1d),
                              "Tuple Comparison", "x", "y", "A", "B", "B/A")
        @test fig isa Makie.Figure
    end

    @testset "plot_signal_vs_background from tuples" begin
        fig = plot_signal_vs_background(
            [(counts_1d, edges_1d)], [(counts_1d .* 2.0, edges_1d)],
            "Tuple SvB", "x", "y", ["Signal"], ["Background"])
        @test fig isa Makie.Figure
    end

    # ── plot_line ────────────────────────────────────────────────────────────

    @testset "plot_line single series" begin
        x = range(0, 2π; length=100)
        fig = plot_line(x, sin.(x), "Sin", "x", "y")
        @test fig isa Makie.Figure
    end

    @testset "plot_line single series with label" begin
        x = range(0, 2π; length=100)
        fig = plot_line(x, sin.(x), "Sin", "x", "y"; label="sin(x)")
        @test fig isa Makie.Figure
    end

    @testset "plot_line multiple series" begin
        x  = range(0, 2π; length=100)
        xs = [collect(x), collect(x)]
        ys = [sin.(x), cos.(x)]
        fig = plot_line(xs, ys, "Trig", "x", "y";
                        label=["sin", "cos"], linestyle=[:solid, :dash])
        @test fig isa Makie.Figure
    end

    @testset "plot_line with options" begin
        x   = range(0.1, 10.0; length=200)
        opts = HEPPlotOptions(ATLAS_label="Internal", energy=13.6,
                              limits=((0.1, 10.0), (0.0, 1.1)))
        fig = plot_line(x, sin.(x) .^ 2, "Power", "x", "y"; options=opts)
        @test fig isa Makie.Figure
    end

    @testset "plot_line log scale" begin
        x   = range(1.0, 100.0; length=50)
        opts = HEPPlotOptions(xscale=log10)
        fig = plot_line(x, x .^ 2, "Power law", "x", "y²"; options=opts)
        @test fig isa Makie.Figure
    end

    @testset "plot_line with markers" begin
        x = collect(range(0, 2π; length=20))
        fig = plot_line(x, sin.(x), "Sin", "x", "y";
                        marker=:circle, markersize=10, label="sin(x)")
        @test fig isa Makie.Figure
    end

end
