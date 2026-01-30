gaudi_colors = ["#cb181d", "#fa6a4a", "#2271b5", "#bdd7e7", "#238b21", "#a1cf42",
                    "#ff8c00", "#fee147"]

ATLAS_colors = ["#3f90da", "#ffa912", "#bd2001", "#94a4a2", "#842db6", "#e76400", "#717581",
                "#92dadd", "#a96b59"]

function set_ATLAS_theme()
    set_texfont_family!(FontFamily("TeXGyreHeros"))
    set_theme!(AtlasTheme())
end

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
            lowclip=:black,),
        Legend=(
            framevisible=false,),
        
)

function add_ATLAS_internal!(ax, sec_text; offset=(250, -20), fontsize=20, energy=13.6)
    text!(ax, 0, 1; text=rich(rich("ATLAS  "; font = "Nimbus Bold Italic", fontsize), rich(sec_text; font = "Nimbus", fontsize=(fontsize-1))),
        align=(:left, :top), offset, space=:relative
    )

    text!(ax, 0, 1; text=L"$\fontfamily{NewComputerModern}\mathbf{\sqrt{s}}$", align=(:left, :top), offset=(offset[1], offset[2] - 30), space=:relative, fontsize=15)
    text!(ax, 0, 1; text=L" = "*string(energy)*" TeV", align=(:left, :top), offset=(offset[1]+25, offset[2] - 30), space=:relative, fontsize=15)

    nothing
end