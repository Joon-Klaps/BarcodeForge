#!/usr/bin/env python3

import argparse
import pandas as pd
from pathlib import Path

from Bio import Phylo, SeqIO


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Verify that all tip labels in a tree appear in a FASTA file."
    )
    p.add_argument("--tree", required=True, type=Path, help="Tree file")
    p.add_argument(
        "--tree_format", required=True, choices=["newick", "nexus"], help="Tree format"
    )
    p.add_argument("--fasta", required=True, type=Path, help="FASTA file")
    p.add_argument("--lineage", required=True, type=Path, help="Lineage File")
    return p.parse_args()


def verify_fasta(tip_labels: set, fasta: str) -> None:
    """
    Verify that all tip labels in a tree appear in a FASTA file.
    """
    # Read the FASTA file and create a set of record IDs
    records = SeqIO.to_dict(SeqIO.parse(fasta, "fasta"))
    seq_ids = set(records.keys())
    # Identify missing labels using set difference
    missing = tip_labels - seq_ids
    if missing:
        missing_labels = ", ".join(sorted(missing))
        raise ValueError(
            f"Labels [{missing_labels}] in tree not found in FASTA file. "
            "Please check the FASTA file and the tree."
        )


def verify_lineage(tip_labels: set, lineage: str) -> None:
    """
    Verify that all tip labels in a tree appear in a lineage file.
    """
    try:
        lineages = set(
            pd.read_csv(lineage, sep="\t", header=None, usecols=[1]).iloc[:, 0]
        )
    except Exception as e:
        raise ValueError(f"Error reading lineage file: {e}")

    missing = tip_labels - lineages
    if missing:
        missing_labels = ", ".join(sorted(missing))
        raise ValueError(
            f"Labels [{missing_labels}] in tree not found in lineage file. "
            "Please check the lineage file and the tree."
        )


def main() -> None:
    args = parse_args()
    try:
        tree = Phylo.read(args.tree, args.tree_format)
    except Exception as e:
        raise ValueError(f"Error reading tree file: {e}")

    tip_labels = {tip.name.strip('"').strip("'") for tip in tree.get_terminals()}

    verify_fasta(tip_labels, args.fasta)
    verify_lineage(tip_labels, args.lineage)
    print("All checks passed. The tree and FASTA file are consistent.")


if __name__ == "__main__":
    main()
