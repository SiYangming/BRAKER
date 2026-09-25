# BRAKER1 v1.8（legacy）

历史版 BRAKER1（约 2015）：仅 RNA-seq 证据。上游 GitHub 最早 tag 为 v2.x，**无此版本**；
自教学包 `BRAKER1_v1.8.tar.gz` 解出，仅作考古/对照，**不要**用于新项目。

新流程：本仓根目录 BRAKER2/3，或 <https://github.com/Gaius-Augustus/BRAKER4>。

```bash
export PATH="$(pwd):$PATH"
braker.pl --species=NAME --genome=genome.fa --bam=rnaseq.bam
```
