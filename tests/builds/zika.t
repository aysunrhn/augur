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

IQ-TREE does not appear to have predictable branch length outputs across architectures even with the same seed.

#$ diff -u "$TEST_DATA_DIR/expected/tree_raw.nwk" "$TMP/out/tree_raw.nwk"

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

TreeTime does not have predictable branch length outputs, so we can't test for exact output matches here.

#$ diff -u "$TEST_DATA_DIR/expected/branch_lengths.json" "$TMP/out/branch_lengths.json"
#$ diff -u "$TEST_DATA_DIR/expected/tree.nwk" "$TMP/out/tree.nwk"
