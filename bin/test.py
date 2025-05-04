import pandas as pd
import altair as alt

# --- Example dummy data (delete once you plug‑in your real df) -----------
df = pd.DataFrame(
    {
        "A123V": [1, 0, 1, 0],
        "E46K" : [0, 1, 0, 1],
        "G512R": [1, 1, 0, 0],
        "P128S": [0, 0, 1, 1],
    },
    index=["Lineage‑1", "Lineage‑2", "Lineage‑3", "Lineage‑4"],
)
# ------------------------------------------------------------------------

def lineage_mutation_heatmap(df: pd.DataFrame) -> alt.Chart:
    """
    Create an interactive lineage‑by‑mutation heat‑map.

    Rows  → lineages
    Columns → mutations
    Color  → presence / absence
    """
    # Wide → long
    long = (
        df.reset_index()
        .melt(id_vars="index", var_name="Mutation", value_name="Present")
        .rename(columns={"index": "Lineage"})
    )

    # Map 0/1 → labels so the legend is clear
    long["Presence"] = long["Present"].map({0: "Absent", 1: "Present"})

    # Interactive selection: click a mutation in the legend to highlight it
    pick = alt.selection_multi(fields=["Mutation"], bind="legend")

    heat = (
        alt.Chart(long)
        .mark_rect()
        .encode(
            x=alt.X(
                "Mutation:O",
                sort=list(df.columns),                # preserve original column order
                axis=alt.Axis(labelAngle=45)
            ),
            y=alt.Y(
                "Lineage:O",
                sort=list(df.index)[::-1]             # most recent lineage on top
            ),
            color=alt.Color(
                "Presence:N",
                scale=alt.Scale(domain=["Absent", "Present"],
                                range=["#E0E0E0", "#3B82F6"]),
                legend=alt.Legend(title="Mutation status")
            ),
            opacity=alt.condition(pick, alt.value(1), alt.value(0.15)),
            tooltip=["Lineage", "Mutation", "Presence"]
        )
        .add_selection(pick)
        .properties(
            width=min(45 * df.shape[1], 900),         # auto‑scale width
            height=min(20 * df.shape[0], 600),        # auto‑scale height
            title="Lineage × Mutation presence/absence"
        )
    )

    # save the chart as an HTML file
    heat.save("lineage_mutation_heatmap.html")

    return heat

lineage_mutation_heatmap(df)
