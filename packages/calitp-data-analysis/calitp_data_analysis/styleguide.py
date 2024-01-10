"""
Set Cal-ITP altair style template,
top-level configuration (for pngs),
and color palettes.

References:

Setting custom Altair theme as .py (Urban):
https://towardsdatascience.com/consistently-beautiful-visualizations-with-altair-themes-c7f9f889602

GH code:
https://github.com/chekos/altair_themes_blog/tree/master/notebooks

Download Google fonts:
https://gist.github.com/ravgeetdhillon/0063aaee240c0cddb12738c232bd8a49

Altair GH issue setting custom theme:
https://github.com/altair-viz/altair/issues/1333
https://discourse.holoviz.org/t/altair-theming/1421/2

https://stackoverflow.com/questions/33061785/can-i-load-google-fonts-with-matplotlib-and-jupyter

matplotlib:
https://github.com/CityOfLosAngeles/los-angeles-citywide-data-style

"""
import altair as alt  # type: ignore
from calitp_data_analysis import calitp_color_palette as cp

# --------------------------------------------------------------#
# Chart parameters
# --------------------------------------------------------------#
font_size = 18
chart_width = 400
chart_height = 250

markColor = "#8CBCCB"
axisColor = "#cbcbcb"
guideLabelColor = "#474747"
guideTitleColor = "#333"
blackTitle = "#333"
backgroundColor = "white"

PALETTE = {
    "category_bright": cp.CALITP_CATEGORY_BRIGHT_COLORS,
    "category_bold": cp.CALITP_CATEGORY_BOLD_COLORS,
    "diverging": cp.CALITP_DIVERGING_COLORS,
    "sequential": cp.CALITP_SEQUENTIAL_COLORS,
}


"""
# Run this in notebook
%%html
<style>
@import url('https://fonts.googleapis.com/css?family=Lato');
</style>
"""


def calitp_theme(
    font_size: int = font_size,
    chart_width: int = chart_width,
    chart_height: int = chart_height,
    markColor: str = markColor,
    axisColor: str = axisColor,
    guideLabelColor: str = guideLabelColor,
    guideTitleColor: str = guideTitleColor,
    blackTitle: str = blackTitle,
    backgroundColor: str = backgroundColor,
    PALETTE: dict = PALETTE,
):
    return {
        # width and height are configured outside the config dict because they are Chart configurations/properties not chart-elements' configurations/properties.
        "width": chart_width,  # from the guide
        "height": chart_height,  # not in the guide
        "background": backgroundColor,
        "config": {
            "title": {
                "fontSize": font_size,
                "anchor": "middle",
                "fontColor": blackTitle,
                "fontWeight": "bold",  # 300 was default. can also use lighter, bold, normal, bolder
                "offset": 20,
            },
            "axis": {
                "domain": True,
                "domainColor": axisColor,
                "grid": True,
                "gridColor": axisColor,
                "gridWidth": 1,
                "labelColor": guideLabelColor,
                "labelFontSize": 10,
                "titleColor": guideTitleColor,
                "tickColor": axisColor,
                "tickSize": 10,
                "titleFontSize": 12,
                "titlePadding": 10,
                "labelPadding": 4,
            },
            "axisBand": {
                "grid": False,
            },
            "range": {
                "category_bright": PALETTE["category_bright"],
                "category_bold": PALETTE["category_bold"],
                "diverging": PALETTE["diverging"],
                "sequential": PALETTE["sequential"],
            },
            "legend": {
                "labelFontSize": 11,
                "symbolType": "square",
                "symbolSize": 30,  # default
                "titleFontSize": 14,
                "titlePadding": 10,
                "padding": 1,
                "orient": "right",
                # "offset": 0, # literally right next to the y-axis.
                "labelLimit": 0,  # legend can fully display text instead of truncating it
            },
            "view": {
                "stroke": "transparent",  # altair uses gridlines to box the area where the data is visualized. This takes that off.
            },
            "group": {
                "fill": backgroundColor,
            },
            # MARKS CONFIGURATIONS #
            "arc": {
                "fill": markColor,
            },
            "area": {
                "fill": markColor,
            },
            "line": {
                # "color": markColor,
                "stroke": markColor,
                "strokeWidth": 2,
            },
            "trail": {
                "color": markColor,
                "stroke": markColor,
                "strokeWidth": 0,
                "size": 1,
            },
            "path": {
                "stroke": markColor,
                "strokeWidth": 0.5,
            },
            "rect": {
                "fill": markColor,
            },
            "point": {
                "filled": True,
                "shape": "circle",
            },
            "shape": {"stroke": markColor},
            "text": {
                "color": markColor,
                "fontSize": 11,
                "align": "center",
                "fontWeight": 400,
                "size": 11,
            },
            "bar": {
                # "size": 40,
                "binSpacing": 2,
                # "continuousBandSize": 30,
                # "discreteBandSize": 30,
                "fill": markColor,
                "stroke": False,
            },
        },
    }


# Let's add in more top-level chart configuratinos
# Need to add more since altair_saver will lose a lot of the theme applied


# Apply top-level chart config but do not set properties (before hconcat, vconcat, etc)
def apply_chart_config(chart: alt.Chart) -> alt.Chart:
    chart = (
        chart.configure(background=backgroundColor)
        .configure_axis(
            domainColor=axisColor,
            grid=True,
            gridColor=axisColor,
            gridWidth=1,
            labelColor=guideLabelColor,
            labelFontSize=10,
            titleColor=guideTitleColor,
            tickColor=axisColor,
            tickSize=10,
            titleFontSize=12,
            titlePadding=10,
            labelPadding=4,
        )
        .configure_axisBand(grid=False)
        .configure_title(
            fontSize=font_size,
            anchor="middle",
            fontWeight=300,
            offset=20,
        )
        .configure_legend(
            labelColor=blackTitle,
            labelFontSize=11,
            padding=1,
            symbolSize=30,
            symbolType="square",
            titleColor=blackTitle,
            titleFontSize=14,
            titlePadding=10,
            labelLimit=0,
        )
    )
    return chart


# Single-chart top-level chart config
# Cannot use this if hconcat or vconcat is used
def preset_chart_config(chart: alt.Chart) -> alt.Chart:
    chart = apply_chart_config(chart).properties(
        width=chart_width,
        height=chart_height,
    )

    return chart
