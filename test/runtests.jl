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

end
