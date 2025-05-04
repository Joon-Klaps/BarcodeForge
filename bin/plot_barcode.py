#!/usr/bin/env python3

"""Plot barcode from CSV file."""

import altair as alt
import pandas as pd
import argparse
import math


def plot(barcode, output_filename):
    # Map 0/1 to labels for discrete presence/absence
    barcode["Presence"] = barcode["z"].map({0: "Absent", 1: "Present"})
    # Determine dynamic dimensions based on unique categories in the dataframe
    n_lineages = len(barcode["Lineage"].unique())
    n_mutations = len(barcode["Mutation"].unique())

    # Calculate width and height dynamically
    width1 = round(math.log(n_mutations)) * 200
    height1 = round(math.log(n_lineages)) * 120

    width2 = n_mutations * 20
    height2 = n_lineages * 20

    box1 = alt.Chart(barcode).mark_rect(
        stroke='#FFFFFF', strokeWidth=0,
    ).encode(
        y='Lineage:O',
        x=alt.X('Mutation:O', axis=alt.Axis(labels=False, tickSize=0)),
        color=alt.Color(
            'Presence:N',
            scale=alt.Scale(domain=["Absent", "Present"], range=['#FFFFFF', '#000000']),
            legend=alt.Legend(title="Mutation status")
        ),
        tooltip=['Lineage', 'Mutation', 'Presence']
    ).properties(
        title=alt.TitleParams(text="Zoomed out Barcode", anchor='start', fontSize=20),
        width=width1,
        height=height1
    ).interactive()

    box2 = alt.Chart(barcode).mark_rect(
        stroke='#BBB', strokeWidth=0.25
    ).encode(
        y='Lineage:O',
        x=alt.X('Mutation:O', axis=alt.Axis(labels=True, labelAngle=45)),
        color=alt.Color(
            'Presence:N',
            scale=alt.Scale(domain=["Absent", "Present"], range=['#FFFFFF', '#000000']),
            legend=alt.Legend(title="Mutation status")
        ),
        tooltip=['Lineage', 'Mutation', 'Presence']
    ).properties(
        title=alt.TitleParams(text="Zoomed in Barcode", anchor='start', fontSize=20),
        width=width2,
        height=height2
    ).interactive()

    # Combine the two charts vertically
    combined_chart = alt.vconcat(
        box2,
        box1,
        spacing=10
    ).resolve_scale(
        color='independent'
    )

    # Save the chart to an HTML file
    combined_chart.save(output_filename)



def parser():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Plot barcode from CSV file."
    )
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        required=True,
        help="Input CSV file"
    )
    parser.add_argument(
        "-o",
        "--output",
        default="barcode.html",
        type=str,
        required=False,
        help="Output HTML file"
    )
    return parser.parse_args()


def main():
    args = parser()
    barcode = pd.read_csv(args.input, header=0, index_col=0)

    # convert barcode dataframe to long format
    barcode = barcode.stack().reset_index()
    barcode.columns = ["Lineage", "Mutation", "z"]
    plot(barcode, args.output)


if __name__ == '__main__':
    main()
