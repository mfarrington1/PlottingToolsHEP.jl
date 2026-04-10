"""
    event_display(jets, largeR_jets, leptons;
                  η_range=-2.5:0.5:2.5, ϕ_range=-3.15:0.45:3.15,
                  jet_R=0.4, largeR_jet_R=1.0,
                  element_labels=["Electrons", "Large R Jets", "Jets"])

Draw a 2-D (η, ϕ) event display for `jets`, `largeR_jets`, and `leptons`.

Each object must support `eta()` and `phi()` from LorentzVectorHEP. Jets and
large-R jets are drawn as circles of radius `jet_R` and `largeR_jet_R` respectively.
Returns the `Figure`.
"""
function event_display(jets, largeR_jets, leptons; η_range =-2.5:0.5:2.5, ϕ_range =-3.15:0.45:3.15, jet_R = 0.4, largeR_jet_R = 1.0, element_labels=["Electrons", "Large R Jets", "Jets"])

    CairoMakie.activate!(type="png")
    fig = CairoMakie.Figure(size=(500,600))
    ax = CairoMakie.Axis(fig[1, 1]; title="Event Display", xlabel="η", ylabel="ϕ", xticks=η_range, yticks=ϕ_range, autolimitaspect=1, limits=((η_range[1], η_range[end]), (ϕ_range[1], ϕ_range[end])))
    el_plot = scatter!(ax, eta.(leptons), phi.(leptons), color=gaudi_colors[3], markersize=12, label="Leptons")
    largeRjet_plot = nothing
    jet_plot = nothing

    for (i, jet) in enumerate(largeR_jets)
        if i == 1
            largeRjet_plot = poly!(ax, Circle(Point2f(eta(jet), phi(jet)), largeR_jet_R), color = :grey, alpha=0.2, label="Large R Jet")
        else
            poly!(ax, Circle(Point2f(eta(jet), phi(jet)), largeR_jet_R), color = :grey, alpha=0.2)
        end
    end

    for (i, jet) in enumerate(jets)
        if i == 1
            jet_plot = poly!(ax, Circle(Point2f(eta(jet), phi(jet)), jet_R), color = gaudi_colors[5], alpha=0.4, label="Jet")
        else
            poly!(ax, Circle(Point2f(eta(jet), phi(jet)), jet_R), color = gaudi_colors[5], alpha=0.4)
        end
    end

    Legend(fig[1, 2], [el_plot, largeRjet_plot, jet_plot], element_labels)
    current_figure()
end