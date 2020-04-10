Integration tests for augur mask.

Try masking sequences without any specified mask.

  $ augur mask --sequences mask/sequences.fasta
  usage: augur mask [-h] --sequences SEQUENCES --mask MASK [--output OUTPUT]
                    [--no-cleanup]
  augur mask: error: the following arguments are required: --mask
  [2]

Mask sequences with a BED file and no specified output file.
Since no output is provided, the input file is overridden with the masked sequences.

  $ cp $TESTDIR/mask/sequences.fasta $TMP/
  $ augur mask --sequences $TMP/sequences.fasta --mask $TESTDIR/mask/mask.bed
  Found 5 sites to mask
  Removing masked sites from FASTA file.

  $ cat $TMP/sequences.fasta
  >sequence_1
  NNNCNN
