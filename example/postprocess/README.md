# BRAKER 结果后处理脚本

教学流水线 BRAKER 段用到的本地辅助脚本（非上游 BRAKER 自带）。

| 脚本 | 来源 | 用途 |
|------|------|------|
| `braker_gtf_fix.pl` | 教学 `run.sh` 内联 Perl | CDS→exon；去掉 transcript/gene/intron/# |
| `gtf2gff3.pl` | 教学包（Utah / Sequence Ontology 系） | GTF → GFF3 |
| `gff3_clear.pl` | [geta](https://github.com/SiYangming/geta) `bin/` | 按前缀重写 gene/mRNA ID |

用法见仓库根目录 [`example.md`](../../example.md)。
