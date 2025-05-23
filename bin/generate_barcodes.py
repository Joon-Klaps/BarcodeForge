#!/usr/bin/env python3

"""Generates barcodes from UShER ."""

# This script is a modified version of the https://github.com/andersen-lab/Freyja/blob/main/freyja/convert_paths2barcodes.py

import pandas as pd
import argparse


def parse_tree_paths(df):
    df = df.set_index('clade')
    # Make sure to check with new tree versions, lineages could get trimmed.
    df = df.drop_duplicates(keep='last')
    df['from_tree_root'] = df['from_tree_root'].fillna('')
    df['from_tree_root'] = df['from_tree_root']\
        .apply(lambda x: x.replace(' ', '').strip('>').split('>'))
    return df


def sortFun(x):
    # sort based on nuc position, ignoring nuc identities
    return int(x[1:(len(x)-1)])


def convert_to_barcodes(df):
    # builds simple barcodes, not accounting for reversions
    df_barcodes = pd.DataFrame()
    for clade in df.index:
        # sparse,binary encoding
        cladeSeries = pd.Series({c: df.loc[clade, 'from_tree_root']
                                      .count(c) for c in
                                 df.loc[clade, 'from_tree_root']}, name=clade)
        df_barcodes = pd.concat((df_barcodes, cladeSeries), axis=1)

    print('separating combined splits')
    df_barcodes = df_barcodes.T
    # dropped since no '' column this time.
    # df_barcodes = df_barcodes.drop(columns='')
    df_barcodes = df_barcodes.fillna(0)
    temp = pd.DataFrame()
    dropList = []
    for c in df_barcodes.columns:
        # if column includes multiple mutations,
        # split into separate columns and concatenates
        if "," in c:
            for mt in c.split(","):
                if mt not in temp.columns:
                    temp = pd.concat((temp, df_barcodes[c].rename(mt)),
                                     axis=1)
                else:
                    # to handle multiple different groups with mut
                    temp[mt] += df_barcodes[c]
            dropList.append(c)
    df_barcodes = df_barcodes.drop(columns=dropList)
    df_barcodes = pd.concat((df_barcodes, temp), axis=1)
    df_barcodes = df_barcodes.groupby(axis=1, level=0).sum()

    # drop columns with empty strings
    # Warning: this is a hack to deal with empty strings in the O/P from matUtils extract.
    if '' in df_barcodes.columns:
        df_barcodes = df_barcodes.drop(columns='')
    return df_barcodes


def reversion_checking(df_barcodes):
    print('checking for mutation pairs')
    # check if a reversion is present.
    flipPairs = [(d, d[-1] + d[1:len(d)-1]+d[0]) for d in df_barcodes.columns
                 if (d[-1] + d[1:len(d)-1]+d[0]) in df_barcodes.columns]
    flipPairs = [list(fp) for fp in list(set(flipPairs))]
    # subtract lower of two pair counts to get the lineage defining mutations
    for fp in flipPairs:
        df_barcodes[fp] = df_barcodes[fp].subtract(df_barcodes[fp].min(axis=1),
                                                   axis=0)
    # drop all unused mutations (i.e. paired mutations with reversions)
    df_barcodes = df_barcodes.drop(
        columns=df_barcodes.columns[df_barcodes.sum(axis=0) == 0])
    return df_barcodes


def test_no_flip_pairs(barcode_file):
    df_barcodes = pd.read_csv(barcode_file,
                              index_col=0)
    flipPairs = [(d, d[-1] + d[1:len(d)-1]+d[0])
                 for d in df_barcodes.columns
                 if (d[-1] + d[1:len(d)-1]+d[0]) in df_barcodes.columns]
    if (len(flipPairs) == 0):
        print('PASS: no flip pairs found')
    else:
        raise Exception('FAIL: flip pairs found: {}'.format(flipPairs))


def identify_chains(df_barcodes):

    sites = [d[0:len(d) - 1]for d in df_barcodes.columns]
    flip_sites = [d[-1] + d[1:len(d) - 1]for d in df_barcodes.columns]
    # for each mutation, find possible sequential mutations
    seq_muts = [[d, df_barcodes.columns[j], d[0:len(d) - 1] +
                 df_barcodes.columns[j][-1]]
                for i, d in enumerate(df_barcodes.columns)
                for j, d2 in enumerate(sites)
                if ((flip_sites[i] == sites[j]) and
                    (d[-1] + d[1:len(d) - 1] + d[0]) !=
                    df_barcodes.columns[j])]

    # confirm that mutation sequence is actually observed
    seq_muts = [sm for sm in seq_muts if df_barcodes[(df_barcodes[sm[0]] > 0) &
                (df_barcodes[sm[1]] > 0)].shape[0] > 0]

    mut_sites = [sortFun(sm[2]) for sm in seq_muts]
    # return only one mutation per site for each iteration
    seq_muts = [seq_muts[i] for i, ms in enumerate(mut_sites)
                if ms not in mut_sites[:i]]
    return seq_muts


def check_mutation_chain(df_barcodes):
    # case when (non-reversion) mutation happens in site with existing mutation
    seq_muts = identify_chains(df_barcodes)
    while len(seq_muts) > 0:
        # combine mutations string into single mutation
        for i, sm in enumerate(seq_muts):
            lin_seq = df_barcodes[(df_barcodes[sm[0]] > 0) &
                                  (df_barcodes[sm[1]] > 0)]
            if sm[2] not in df_barcodes.columns:
                # combination leads to new mutation
                newCol = pd.Series([(1 if dfi in lin_seq.index else 0)
                                   for dfi in df_barcodes.index], name=sm[2],
                                   index=df_barcodes.index)
                # print('lin seq\n',lin_seq)
                # print(df_barcodes.index)
                # print(newCol)
                df_barcodes = pd.concat([df_barcodes, newCol], axis=1)
            else:
                # combining leads to already existing mutation
                # just add in that mutation
                df_barcodes.loc[lin_seq.index, sm[2]] = 1
            # remove constituent mutations
            df_barcodes.loc[lin_seq.index, sm[0:2]] -= 1
        # drop all unused mutations
        # print('before_trim\n',df_barcodes)
        df_barcodes = df_barcodes.drop(
            columns=df_barcodes.columns[df_barcodes.sum(axis=0) == 0])
        # in case mutation path leads to a return to the reference.
        df_barcodes = reversion_checking(df_barcodes)
        seq_muts = identify_chains(df_barcodes)
    return df_barcodes


def parser():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('-i', '--input', metavar='input', type=str,
                        help='input file')
    parser.add_argument('-p', '--prefix', default='' ,metavar='prefix', type=str,
                        help='prefix for lineages')
    parser.add_argument('-o', '--output', default="barcode.csv", metavar='output', type=str,
                        help='output file')
    args = parser.parse_args()
    return args


def replace_underscore_with_dash(df):
    '''
    Replace underscores with dashes in the index of the dataframe
    
    Args:
    df: pandas dataframe

    Returns:
    df: pandas dataframe with underscores replaced with dashes
    '''
    df.index = [i.replace('_', '-') for i in df.index]
    return df


def main():
    args = parser()
    df = pd.read_csv(args.input, sep='\t')
    df = parse_tree_paths(df)
    df_barcodes = convert_to_barcodes(df)
    if args.prefix != '':
        # append prefix to all values in the index
        df_barcodes.index = [args.prefix + '-' + str(i) for i in df_barcodes.index]
    df_barcodes = reversion_checking(df_barcodes)
    df_barcodes = check_mutation_chain(df_barcodes)
    df_barcodes = replace_underscore_with_dash(df_barcodes)
    # sort the columns by the number between the first and last character
    df_barcodes = df_barcodes.reindex(sorted(df_barcodes.columns,
                                             key=sortFun), axis=1)
    df_barcodes.to_csv(args.output)
    test_no_flip_pairs(args.output)


if __name__ == '__main__':
    main()
