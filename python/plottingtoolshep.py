"""
plottingtoolshep.py
===================
Python companion module for PlottingToolsHEP.jl.

Wraps juliacall to provide numpy-friendly access to all public plotting
functions.  The Julia session is initialised on first import; subsequent
imports reuse the running session.

Requirements
------------
- juliacall  (pip install juliacall)
- numpy      (pip install numpy)

The Julia package PlottingToolsHEP.jl must be visible to the active Julia
environment.  To register it for development use::

    julia --project -e 'using Pkg; Pkg.develop(path="/path/to/PlottingToolsHEP.jl")'

Usage
-----
>>> import sys; sys.path.insert(0, "/path/to/PlottingToolsHEP.jl/python")
>>> import plottingtoolshep as pth
>>> fig = pth.plot_hist((counts, edges), "My plot", "x [GeV]", "Events")
>>> pth.save_figure(fig, "my_plot.png")
"""

from __future__ import annotations

import numpy as np

# ---------------------------------------------------------------------------
# juliacall bootstrap
# ---------------------------------------------------------------------------
try:
    from juliacall import Main as jl, JuliaError  # type: ignore[import]
except ImportError as exc:
    raise ImportError(
        "juliacall is not installed.  Run: pip install juliacall"
    ) from exc

jl.seval("using PlottingToolsHEP, CairoMakie, FHist")

_jl_pkg = jl.PlottingToolsHEP

# ---------------------------------------------------------------------------
# Color palettes — exported as plain Python lists
# ---------------------------------------------------------------------------
#: 9-color ATLAS collaboration palette (hex strings).
ATLAS_colors: list[str] = list(_jl_pkg.ATLAS_colors)

#: 8-color Gaudi-inspired palette (hex strings).
gaudi_colors: list[str] = list(_jl_pkg.gaudi_colors)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _to_hist1d(h):
    """
    Convert a ``(counts, edges)`` tuple to a Julia ``Hist1D``, or pass through.

    Parameters
    ----------
    h : tuple ``(counts, edges)`` or Julia Hist1D proxy
        Both arrays are cast to ``float64`` before construction.

    Returns
    -------
    Julia Hist1D proxy, or the original object if it is not a 2-tuple.
    """
    if isinstance(h, (tuple, list)) and len(h) == 2:
        counts = np.asarray(h[0], dtype=np.float64)
        edges  = np.asarray(h[1], dtype=np.float64)
        return jl.FHist.Hist1D(
            bincounts=counts, binedges=edges,
            sumw2=counts, nentries=int(round(counts.sum())), overflow=False,
        )
    return h


def _to_hist2d(h):
    """
    Convert a ``(counts_matrix, xedges, yedges)`` tuple to a Julia ``Hist2D``, or
    pass through.

    Parameters
    ----------
    h : tuple ``(counts_matrix, xedges, yedges)`` or Julia Hist2D proxy

    Returns
    -------
    Julia Hist2D proxy, or the original object if it is not a 3-tuple.
    """
    if isinstance(h, (tuple, list)) and len(h) == 3:
        counts = np.asarray(h[0], dtype=np.float64)
        xe     = np.asarray(h[1], dtype=np.float64)
        ye     = np.asarray(h[2], dtype=np.float64)
        return jl.FHist.Hist2D(
            bincounts=counts, binedges=(xe, ye),
            sumw2=counts, nentries=int(round(counts.sum())), overflow=False,
        )
    return h


def _to_hist(h):
    """Dispatch to :func:`_to_hist1d` or :func:`_to_hist2d` based on tuple length."""
    if isinstance(h, (tuple, list)):
        return _to_hist2d(h) if len(h) == 3 else _to_hist1d(h)
    return h

# ---------------------------------------------------------------------------
# HEPPlotOptions convenience constructor
# ---------------------------------------------------------------------------

def HEPPlotOptions(
    *,
    yscale=None,
    xscale=None,
    xticks=None,
    yticks=None,
    limits=None,
    ATLAS_label: str | None = None,
    ATLAS_label_offset=None,
    energy: float = 13.6,
):
    """
    Construct a Julia ``HEPPlotOptions`` struct and return it.

    All parameters are optional; unspecified parameters take the Julia default.

    Parameters
    ----------
    yscale, xscale : Julia scale function, optional
        E.g. ``jl.log10`` for a logarithmic axis.
    xticks, yticks : array-like or Julia tick specification, optional
    limits : tuple of two 2-tuples, optional
        ``((xmin, xmax), (ymin, ymax))``.
    ATLAS_label : str or None
        Secondary text placed after "ATLAS" (e.g. ``"Internal"``).
        ``None`` suppresses the label entirely.
    ATLAS_label_offset : tuple of two ints, optional
        Pixel offset from the top-left corner; default ``(30, -20)``.
    energy : float
        Centre-of-mass energy in TeV shown in the ATLAS label.

    Returns
    -------
    Julia ``HEPPlotOptions`` struct proxy.
    """
    kwargs: dict = {"energy": energy}
    if yscale             is not None: kwargs["yscale"]             = yscale
    if xscale             is not None: kwargs["xscale"]             = xscale
    if xticks             is not None: kwargs["xticks"]             = xticks
    if yticks             is not None: kwargs["yticks"]             = yticks
    if limits             is not None: kwargs["limits"]             = limits
    if ATLAS_label        is not None: kwargs["ATLAS_label"]        = ATLAS_label
    if ATLAS_label_offset is not None: kwargs["ATLAS_label_offset"] = ATLAS_label_offset
    return _jl_pkg.HEPPlotOptions(**kwargs)

# ---------------------------------------------------------------------------
# Public plotting API
# ---------------------------------------------------------------------------

def plot_hist(
    hist,
    title: str,
    xlabel: str,
    ylabel: str,
    *,
    label=None,
    normalize_hist: bool = False,
    colticks=None,
    colorbar_label: str = "",
    colorscale=None,
    colorrange=None,
    options=None,
):
    """
    Plot a single 1-D or 2-D histogram and return the Makie ``Figure``.

    Parameters
    ----------
    hist : Julia Hist1D/Hist2D proxy, or tuple
        Pass a 2-tuple ``(counts, edges)`` for a pre-binned 1-D histogram, or a
        3-tuple ``(counts_matrix, xedges, yedges)`` for a 2-D histogram.
        NumPy arrays are accepted and converted automatically.
    title, xlabel, ylabel : str
        Axis title and labels.
    label : str, optional
        Legend entry for the series.  Activates the legend when set.
    normalize_hist : bool
        Normalise the histogram to unit area before plotting.
    colticks : array-like, optional
        Explicit tick positions for the 2-D colorbar.
    colorbar_label : str
        Label next to the colorbar (2-D only).
    colorscale : Julia function, optional
        Color scale for the heatmap (e.g. ``jl.log10``).
    colorrange : tuple, optional
        ``(min, max)`` color range for the heatmap.
    options : Julia ``HEPPlotOptions`` proxy, optional
        Created via :func:`HEPPlotOptions`.

    Returns
    -------
    Makie ``Figure`` proxy.  Save with :func:`save_figure`.
    """
    hist = _to_hist(hist)
    kwargs: dict = {
        "normalize_hist": normalize_hist,
        "colorbar_label": colorbar_label,
    }
    if label      is not None: kwargs["label"]      = label
    if colticks   is not None: kwargs["colticks"]   = colticks
    if colorscale is not None: kwargs["colorscale"] = colorscale
    if colorrange is not None: kwargs["colorrange"] = colorrange
    if options    is not None: kwargs["options"]    = options
    return _jl_pkg.plot_hist(hist, title, xlabel, ylabel, **kwargs)


def plot_line(
    x,
    y,
    title: str,
    xlabel: str,
    ylabel: str,
    *,
    label=None,
    color=None,
    linestyle=None,
    marker=None,
    markersize: float = 8,
    options=None,
):
    """
    Plot one or more lines from *x* and *y* data and return the Makie ``Figure``.

    Parameters
    ----------
    x, y : array-like or list of array-like
        Pass plain arrays for a single series, or lists of arrays for multiple
        series.  NumPy arrays are accepted.
    title, xlabel, ylabel : str
    label : str or list of str, optional
        Legend label(s).  Activates the legend when set.
    color : color or list of colors, optional
        Line color(s).  Defaults to ``ATLAS_colors``.
    linestyle : Julia line-style symbol or list, optional
        E.g. ``jl.seval(":dash")`` for dashed lines.
    marker : Julia marker symbol, optional
        Draw a marker at each data point, e.g. ``jl.seval(":circle")``.
    markersize : float
        Size of the markers in points (default 8).
    options : Julia ``HEPPlotOptions`` proxy, optional

    Returns
    -------
    Makie ``Figure`` proxy.  Save with :func:`save_figure`.
    """
    kwargs: dict = {}
    if label      is not None: kwargs["label"]      = label
    if color      is not None: kwargs["color"]      = color
    if linestyle  is not None: kwargs["linestyle"]  = linestyle
    if marker     is not None: kwargs["marker"]     = marker
    if options    is not None: kwargs["options"]    = options
    kwargs["markersize"] = markersize
    return _jl_pkg.plot_line(x, y, title, xlabel, ylabel, **kwargs)


def multi_plot(
    hists,
    title: str,
    xlabel: str,
    ylabel: str,
    hist_labels,
    *,
    signal_hists=None,
    signal_labels=None,
    data_hist=None,
    data_hist_style: str = "scatter",
    data_label: str = "Data",
    normalize_hists: str = "",
    stack: bool = False,
    lower_panel: str = "none",
    ratio_label: str = "Data/MC",
    plot_errors: bool = True,
    color=None,
    legend_position: str = "inside",
    legend_align=None,
    options=None,
):
    """
    Overlay multiple histograms on one axis and return the Makie ``Figure``.

    Parameters
    ----------
    hists : list of Julia Hist1D proxies or ``(counts, edges)`` tuples
        Main (background) histograms.
    title, xlabel, ylabel : str
    hist_labels : list of str
        Legend labels for each histogram in *hists*.
    signal_hists : list of Hist1D proxies or tuples, optional
        Signal histograms, drawn with dashed lines.
    signal_labels : list of str, optional
        Legend labels for *signal_hists*.
    data_hist : Hist1D proxy or tuple, optional
        Data histogram drawn in black on top of the backgrounds.
    data_hist_style : {"scatter", "stephist"}
        Drawing style for *data_hist*.
    data_label : str
        Legend label for *data_hist*.
    normalize_hists : {"", "individual", "total"}
        Normalisation mode applied before plotting.
    stack : bool
        Draw background histograms as a filled stacked histogram.
    lower_panel : {"none", "ratio", "s_sqrt_b"}
        Sub-panel drawn below the main axis.  Plain strings are accepted —
        no Julia ``Symbol`` syntax needed from Python.
    ratio_label : str
        Y-axis label for the ratio sub-panel.
    plot_errors : bool
        Overlay Poisson error bars on each histogram.
    color : list of colors, optional
        Per-histogram colors.  Defaults to ``ATLAS_colors``.
    legend_position : {"inside", "side"}
        Legend placement.  Plain strings are accepted.
    legend_align : Julia NamedTuple, optional
        ``(valign=..., halign=...)`` for inside-legend fine-tuning.
    options : Julia ``HEPPlotOptions`` proxy, optional

    Returns
    -------
    Makie ``Figure`` proxy.  Save with :func:`save_figure`.
    """
    jl_hists = [_to_hist1d(h) for h in hists]
    kwargs: dict = {
        "data_hist_style": data_hist_style,
        "data_label":      data_label,
        "normalize_hists": normalize_hists,
        "stack":           stack,
        "lower_panel":     lower_panel,
        "ratio_label":     ratio_label,
        "plot_errors":     plot_errors,
        "legend_position": legend_position,
    }
    if signal_hists  is not None:
        kwargs["signal_hists"]  = [_to_hist1d(h) for h in signal_hists]
    if signal_labels is not None:
        kwargs["signal_labels"] = signal_labels
    if data_hist     is not None:
        kwargs["data_hist"]     = _to_hist1d(data_hist)
    if color         is not None:
        kwargs["color"]         = color
    if legend_align  is not None:
        kwargs["legend_align"]  = legend_align
    if options       is not None:
        kwargs["options"]       = options
    return _jl_pkg.multi_plot(jl_hists, title, xlabel, ylabel, hist_labels, **kwargs)


def plot_comparison(
    hist1,
    hist2,
    title: str,
    xlabel: str,
    ylabel: str,
    hist1_label: str,
    hist2_label: str,
    comp_label: str,
    *,
    normalize_hists: bool = True,
    plot_as_data=None,
    options=None,
):
    """
    Overlay two histograms with a ratio panel and return the Makie ``Figure``.

    Parameters
    ----------
    hist1, hist2 : Julia Hist1D proxy or ``(counts, edges)`` tuple
        *hist1* is the reference ("MC"); *hist2* is the overlay ("data").
        The ratio panel shows hist2 / hist1.
    title, xlabel, ylabel : str
    hist1_label, hist2_label : str
    comp_label : str
        Y-axis label for the ratio sub-panel.
    normalize_hists : bool
        Individually normalise both histograms before plotting.
    plot_as_data : list of two bools, optional
        Set the second element to ``True`` to draw *hist2* as scatter points.
    options : Julia ``HEPPlotOptions`` proxy, optional

    Returns
    -------
    Makie ``Figure`` proxy.  Save with :func:`save_figure`.
    """
    hist1 = _to_hist1d(hist1)
    hist2 = _to_hist1d(hist2)
    kwargs: dict = {"normalize_hists": normalize_hists}
    if plot_as_data is not None: kwargs["plot_as_data"] = plot_as_data
    if options      is not None: kwargs["options"]      = options
    return _jl_pkg.plot_comparison(
        hist1, hist2, title, xlabel, ylabel,
        hist1_label, hist2_label, comp_label,
        **kwargs,
    )


def plot_signal_vs_background(
    signal_hists,
    bkg_hists,
    title: str,
    xlabel: str,
    ylabel: str,
    signal_labels,
    bkg_labels,
    *,
    normalize_hists: str = "",
    stack: bool = False,
    plot_s_sqrt_b: bool = True,
    color=None,
    options=None,
):
    """
    Overlay signal and background histograms with an optional S/√B panel.

    Parameters
    ----------
    signal_hists : list of Julia Hist1D proxies or ``(counts, edges)`` tuples
    bkg_hists : list of Julia Hist1D proxies or ``(counts, edges)`` tuples
    title, xlabel, ylabel : str
    signal_labels, bkg_labels : list of str
    normalize_hists : {"", "individual", "total"}
    stack : bool
        Draw backgrounds as a stacked histogram.
    plot_s_sqrt_b : bool
        Draw the cumulative S/√B significance panel below the main axis.
    color : list of colors, optional
    options : Julia ``HEPPlotOptions`` proxy, optional

    Returns
    -------
    Makie ``Figure`` proxy.  Save with :func:`save_figure`.
    """
    jl_sig = [_to_hist1d(h) for h in signal_hists]
    jl_bkg = [_to_hist1d(h) for h in bkg_hists]
    kwargs: dict = {
        "normalize_hists": normalize_hists,
        "stack":           stack,
        "plot_s_sqrt_b":   plot_s_sqrt_b,
    }
    if color   is not None: kwargs["color"]   = color
    if options is not None: kwargs["options"] = options
    return _jl_pkg.plot_signal_vs_background(
        jl_sig, jl_bkg, title, xlabel, ylabel,
        signal_labels, bkg_labels,
        **kwargs,
    )

# ---------------------------------------------------------------------------
# Figure I/O
# ---------------------------------------------------------------------------

def save_figure(fig, path: str, *, px_per_unit: float = 2.0) -> None:
    """
    Save a Makie ``Figure`` returned by any plotting function to a file.

    Parameters
    ----------
    fig : Makie ``Figure`` proxy
        The figure to save, as returned by any ``plot_*`` function.
    path : str
        Output file path.  The extension determines the format
        (``.png``, ``.pdf``, ``.svg``).
    px_per_unit : float
        Resolution multiplier passed to ``CairoMakie.save``.  Default ``2.0``
        gives 2× resolution, suitable for publication figures.
    """
    jl.CairoMakie.save(path, fig, px_per_unit=px_per_unit)
