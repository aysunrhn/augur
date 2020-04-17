Run an example Zika build with augur.

Parse a FASTA whose defline contains metadata into separate sequence and metadata files.

  $ TEST_DATA_DIR="$TESTDIR/zika"
  $ mkdir -p "$TMP/out"
  $ augur parse \
  >   --sequences "$TEST_DATA_DIR/data/zika.fasta" \
  >   --output-sequences "$TMP/out/sequences.fasta" \
  >   --output-metadata "$TMP/out/metadata.tsv" \
  >   --fields strain virus accession date region country division city db segment authors url title journal paper_url \
  >   --prettify-fields region country division city

  $ diff -u "$TEST_DATA_DIR/expected/sequences.fasta" "$TMP/out/sequences.fasta"

Filter sequences by a minimum date and an exclusion list and only keep one sequence per country, year, and month.

  $ augur filter \
  >   --sequences "$TEST_DATA_DIR/expected/sequences.fasta" \
  >   --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >   --exclude "$TEST_DATA_DIR/config/dropped_strains.txt" \
  >   --output "$TMP/out/filtered.fasta" \
  >   --group-by country year month \
  >   --sequences-per-group 1 \
  >   --subsample-seed 314159 \
  >   --min-date 2012 > /dev/null

  $ diff -u "$TEST_DATA_DIR/expected/filtered.fasta" "$TMP/out/filtered.fasta"

Align filtered sequences to a specific reference sequence and fill any gaps.

  $ augur align \
  >  --sequences "$TEST_DATA_DIR/expected/filtered.fasta" \
  >  --reference-sequence "$TEST_DATA_DIR/config/zika_outgroup.gb" \
  >  --output "$TMP/out/aligned.fasta" \
  >  --fill-gaps > /dev/null

  $ diff -u "$TEST_DATA_DIR/expected/aligned.fasta" "$TMP/out/aligned.fasta"

Build a tree from the multiple sequence alignment.

  $ augur tree \
  >  --alignment "$TEST_DATA_DIR/expected/aligned.fasta" \
  >  --output "$TMP/out/tree_raw.nwk" \
  >  --method iqtree \
  >  --tree-builder-args "-seed 314159" > /dev/null

  $ python "$TESTDIR/../../scripts/diff_trees.py" "$TEST_DATA_DIR/expected/tree_raw.nwk" "$TMP/out/tree_raw.nwk" --significant-digits 5
  {}

Build a time tree from the existing tree topology, the multiple sequence alignment, and the strain metadata.

  $ augur refine \
  >  --tree "$TEST_DATA_DIR/expected/tree_raw.nwk" \
  >  --alignment "$TEST_DATA_DIR/expected/aligned.fasta" \
  >  --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >  --output-tree "$TMP/out/tree.nwk" \
  >  --output-node-data "$TMP/out/branch_lengths.json" \
  >  --timetree \
  >  --coalescent opt \
  >  --date-confidence \
  >  --date-inference marginal \
  >  --clock-filter-iqd 4 > /dev/null

Confirm that TreeTime trees match expected topology and branch lengths.

  $ python "$TESTDIR/../../scripts/diff_trees.py" "$TEST_DATA_DIR/expected/tree.nwk" "$TMP/out/tree.nwk" --significant-digits 2
  {}

#$ diff -u "$TEST_DATA_DIR/expected/branch_lengths.json" "$TMP/out/branch_lengths.json"

Calculate tip frequencies from the tree.

  $ augur frequencies \
  >  --method kde \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >  --pivot-interval 3 \
  >  --output "$TMP/out/zika_tip-frequencies.json" > /dev/null

  $ diff -u "$TEST_DATA_DIR/expected/auspice/zika_tip-frequencies.json" "$TMP/out/zika_tip-frequencies.json"

Infer ancestral sequences from the tree.

  $ augur ancestral \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --alignment "$TEST_DATA_DIR/expected/aligned.fasta" \
  >  --infer-ambiguous \
  >  --output-node-data "$TMP/out/nt_muts.json" \
  >  --inference joint > /dev/null

  $ diff -u "$TEST_DATA_DIR/expected/nt_muts.json" "$TMP/out/nt_muts.json"

Infer ancestral traits from the tree.

  $ augur traits \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --weights "$TEST_DATA_DIR/config/trait_weights.csv" \
  >  --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >  --output-node-data "$TMP/out/traits.json" \
  >  --columns country region \
  >  --sampling-bias-correction 3 \
  >  --confidence > /dev/null

NOTE: entropy and confidence values of inferred traits are not stable across multiple runs with the same input.

#$ diff -u "$TEST_DATA_DIR/expected/traits.json" "$TMP/out/traits.json"

Translate inferred ancestral and observed nucleotide sequences to amino acid mutations.

  $ augur translate \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --ancestral-sequences "$TEST_DATA_DIR/expected/nt_muts.json" \
  >  --reference-sequence "$TEST_DATA_DIR/config/zika_outgroup.gb" \
  >  --output-node-data "$TMP/out/aa_muts.json" > /dev/null

NOTE: translated output stores the path to the reference sequence as it is passed to augur translate.
Since tests are run with absolute paths that will differ by test environment, these reference paths are not stable.

#$ diff -u "$TEST_DATA_DIR/expected/aa_muts.json" "$TMP/out/aa_muts.json"

Export JSON files as v1 auspice outputs.

  $ augur export v1 \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >  --node-data "$TEST_DATA_DIR/expected/branch_lengths.json" \
  >              "$TEST_DATA_DIR/expected/traits.json" \
  >              "$TEST_DATA_DIR/expected/nt_muts.json" \
  >              "$TEST_DATA_DIR/expected/aa_muts.json" \
  >  --colors "$TEST_DATA_DIR/config/colors.tsv" \
  >  --auspice-config "$TEST_DATA_DIR/config/auspice_config_v1.json" \
  >  --output-tree "$TMP/out/v1_zika_tree.json" \
  >  --output-meta "$TMP/out/v1_zika_meta.json" \
  >  --output-sequence "$TMP/out/v1_zika_seq.json" > /dev/null

  $ augur validate export-v1 "$TMP/out/v1_zika_meta.json" "$TMP/out/v1_zika_tree.json" > /dev/null

Export JSON files as v2 auspice outputs.

  $ augur export v2 \
  >  --tree "$TEST_DATA_DIR/expected/tree.nwk" \
  >  --metadata "$TEST_DATA_DIR/expected/metadata.tsv" \
  >  --node-data "$TEST_DATA_DIR/expected/branch_lengths.json" \
  >              "$TEST_DATA_DIR/expected/traits.json" \
  >              "$TEST_DATA_DIR/expected/nt_muts.json" \
  >              "$TEST_DATA_DIR/expected/aa_muts.json" \
  >  --colors "$TEST_DATA_DIR/config/colors.tsv" \
  >  --auspice-config "$TEST_DATA_DIR/config/auspice_config_v2.json" \
  >  --output "$TMP/out/v2_zika.json" \
  >  --title 'Real-time tracking of Zika virus evolution -- v2 JSON' \
  >  --panels tree map entropy frequencies > /dev/null

  $ augur validate export-v2 "$TMP/out/v2_zika.json" > /dev/null
