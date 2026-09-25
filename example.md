# BRAKER 运行示例（ETP）

教学流水线「使用 BRAKER」段的通用写法：软屏蔽基因组 + RNA-seq BAM + 同源蛋白（`--etpmode`）。
后处理脚本在 [`example/postprocess/`](example/postprocess/)。

前置：已按 [INSTALL.md](INSTALL.md) 装好 `braker.pl` 及依赖；GeneMark 密钥 `~/.gm_key`。

---

## 1. 输入数据

本仓已有小示例（`example/`）：

| 文件 | 说明 |
|------|------|
| [`example/genome.fa`](example/genome.fa) | 示例基因组 |
| [`example/proteins.fa`](example/proteins.fa) | 同源蛋白 |
| [`example/RNAseq.hints`](example/RNAseq.hints) | 无 BAM 时可改用 `--hints=` |

RNA-seq BAM **不在 git**（体积大），与上游测试相同，按需下载：

```bash
cd example
wget -c http://topaz.gatech.edu/GeneMark/Braker/RNAseq.bam
# 或：curl -fL -o RNAseq.bam http://topaz.gatech.edu/GeneMark/Braker/RNAseq.bam
```

自备数据时，将下文路径换成你的 softmask 基因组 / 排序 BAM / 蛋白 FASTA 即可。

---

## 2. 环境变量（可选）

若依赖不在默认 PATH，按实际安装前缀导出（勿写死教学机路径）：

```bash
export AUGUSTUS_CONFIG_PATH=.../augustus/config
export AUGUSTUS_BIN_PATH=.../augustus/bin
export AUGUSTUS_SCRIPTS_PATH=.../augustus/scripts
export GENEMARK_PATH=.../gmes_linux_64
export BAMTOOLS_PATH=...
export SAMTOOLS_PATH=...
export ALIGNMENT_TOOL_PATH=.../gth-.../bin
export BLAST_PATH=.../ncbi-rmblast.../bin
export DIAMOND_PATH=...
export PYTHON3_PATH=...
export CDBTOOLS_PATH=...   # 若用 PASA 自带 cdbfasta 等
```

将后处理脚本加入 PATH：

```bash
REPO="$(cd "$(dirname "$0")" && pwd)"   # 或手动设为本仓根目录
export PATH="$REPO/example/postprocess:$PATH"
```

---

## 3. 运行 BRAKER（ETP）

```bash
cd example   # 或任意工作目录
# 同源蛋白 ID：去掉空白描述、点号换下划线（就地副本，不改原文件）
cp proteins.fa homolog.fasta
perl -p -i -e 'if (m/^>/) { s/\s+.*//; s/\./_/g; }' homolog.fasta

braker.pl \
  --species=sp_braker_example \
  --genome=genome.fa \
  --bam=RNAseq.bam \
  --prot_seq=homolog.fasta \
  --cores 8 \
  --etpmode \
  --softmasking \
  --workingdir=braker
```

仅 RNA-seq（无蛋白 / 非 etpmode）：

```bash
braker.pl --species=sp_braker_et --genome=genome.fa --bam=RNAseq.bam \
  --cores 8 --softmasking --workingdir=braker
```

无 BAM、用 hints：

```bash
braker.pl --species=sp_braker_hints --genome=genome.fa \
  --hints=RNAseq.hints --prot_seq=homolog.fasta \
  --cores 8 --etpmode --softmasking --workingdir=braker
```

---

## 4. 后处理 → GFF3

```bash
# CDS→exon；去掉 transcript / gene / intron / 注释行
braker_gtf_fix.pl braker/braker.gtf > braker.gtf

gtf2gff3.pl braker.gtf > braker.gff3
gff3_clear.pl --prefix braker braker.gff3 > braker.gff3.tmp
mv braker.gff3.tmp braker.gff3
```

产物：`braker/braker.gtf`（原始）→ 工作区 `braker.gtf` / `braker.gff3`。

---

## 脚本一览

见 [`example/postprocess/README.md`](example/postprocess/README.md)。
