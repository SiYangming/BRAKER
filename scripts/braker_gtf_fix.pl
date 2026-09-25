#!/usr/bin/env perl
# From teaching BRAKER post-step: copy CDS→exon; drop transcript/gene/intron/# lines.
use strict;
use warnings;
while (<>) {
    if (m/\tCDS\t/) { print; s/\tCDS\t/\texon\t/; print; }
    elsif (m/\ttranscript\t/) { next; }
    elsif (m/^#/) { next; }
    elsif (m/\tgene\t/) { next; }
    elsif (m/\tintron\t/) { next; }
    else { print; }
}
