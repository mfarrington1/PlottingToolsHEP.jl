using PlottingToolsHEP, Random, CairoMakie, FHist, Revise

h1 = Hist1D(randn(10000); binedges=-6:0.1:6)
h2 = Hist1D(2*randn(10000); binedges=-6:0.1:6)
h3 = Hist1D(randn(10000) .+1; binedges=-6:0.1:6)
h4 = Hist2D((randn(10000), randn(10000)))

set_ATLAS_theme()

plot_hist(h1, "", L"$p_T$ [GeV]", "Events"; ATLAS_label="Internal", limits=((-6, 6), (0, 1000)), normalize_hist=false, energy=13)
plot_hist(h4, "", L"\eta", L"\phi"; colorbar_label="Events")
plot_comparison(h1, h2, "", L"\eta", "Events", "h1", "h2", "h1/h2"; ATLAS_label="Internal", energy=14)
multi_plot([h1, h2, h3], "", L"$p_T$ [GeV]", "Events", ["h1", "h2", "h3"]; ATLAS_label="Internal", stack=true)