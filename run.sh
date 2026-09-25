#!/usr/bin/env bash
# =============================================================================
# run.sh — BRAKER2 基因预测通用配方（ETP：RNA-seq BAM + 同源蛋白）
#
# 归属：https://github.com/SiYangming/BRAKER （本 fork；见 INSTALL.md）
# 来源整理：教学 run.sh「使用 BRAKER」段（去硬编码路径）
#
# 前置：braker.pl 在 PATH（见同目录 install.sh / INSTALL.md）
# 在工作目录执行；通过环境变量传入输入
#
# 必填：
#   GENOME     软屏蔽基因组 FASTA
#   BAM        RNA-seq 比对 BAM（已排序）
#   SPECIES    AUGUSTUS/BRAKER 物种名（新建 training 用）
# 可选：
#   PROT_SEQ   同源蛋白 FASTA（设则默认 --etpmode）
#   CORES      线程（默认 8）
#   WORKINGDIR BRAKER 输出目录名（默认 braker）
#   SKIP_ETP   设为 1 则仅 RNA-seq（不加 --etpmode / --prot_seq）
#   SOFTMASKING 默认 1；设 0 关闭 --softmasking
#   GFF3_PREFIX gff3 基因 ID 前缀清理用（默认 braker；需 gff3_clear.pl）
#
# 示例：
#   GENOME=genome.softmask.fasta BAM=rnaseq.sort.bam PROT_SEQ=homolog.fasta \
#     SPECIES=myspecies_braker CORES=8 bash run.sh
# =============================================================================
set -euo pipefail

GENOME="${GENOME:?set GENOME=path/to/genome.softmask.fasta}"
BAM="${BAM:?set BAM=path/to/rnaseq.sort.bam}"
SPECIES="${SPECIES:?set SPECIES=augustus_species_name}"
PROT_SEQ="${PROT_SEQ:-}"
CORES="${CORES:-8}"
WORKINGDIR="${WORKINGDIR:-braker}"
SKIP_ETP="${SKIP_ETP:-0}"
SOFTMASKING="${SOFTMASKING:-1}"
GFF3_PREFIX="${GFF3_PREFIX:-braker}"

command -v braker.pl >/dev/null || {
    echo "[ERROR] 未找到 braker.pl；先运行本仓 install.sh 或见 INSTALL.md" >&2
    exit 1
}

[[ -f "$GENOME" ]] || { echo "[ERROR] GENOME 不存在: $GENOME" >&2; exit 1; }
[[ -f "$BAM" ]] || { echo "[ERROR] BAM 不存在: $BAM" >&2; exit 1; }

# 可选：若环境已导出依赖路径则沿用（与教学脚本变量名一致）
: "${AUGUSTUS_CONFIG_PATH:=}"
: "${AUGUSTUS_BIN_PATH:=}"
: "${AUGUSTUS_SCRIPTS_PATH:=}"
: "${GENEMARK_PATH:=}"
: "${BAMTOOLS_PATH:=}"
: "${SAMTOOLS_PATH:=}"
: "${ALIGNMENT_TOOL_PATH:=}"
: "${BLAST_PATH:=}"
: "${DIAMOND_PATH:=}"
: "${PYTHON3_PATH:=}"
: "${CDBTOOLS_PATH:=}"

echo "[run] braker.pl species=$SPECIES genome=$GENOME bam=$BAM cores=$CORES"

cmd=(braker.pl "--species=${SPECIES}" "--genome=${GENOME}" "--bam=${BAM}" "--cores" "${CORES}"
     "--workingdir=${WORKINGDIR}")

if [[ "$SOFTMASKING" == "1" ]]; then
    cmd+=(--softmasking)
fi

if [[ "$SKIP_ETP" != "1" && -n "$PROT_SEQ" ]]; then
    [[ -f "$PROT_SEQ" ]] || { echo "[ERROR] PROT_SEQ 不存在: $PROT_SEQ" >&2; exit 1; }
    # 与教学一致：同源蛋白 ID 去空白/点号（就地副本，不改原文件）
    prot_work="$(mktemp "${TMPDIR:-/tmp}/braker_prot.XXXXXX.fasta")"
    trap 'rm -f "${prot_work:-}"' EXIT
    cp "$PROT_SEQ" "$prot_work"
    perl -p -i -e 'if (m/^>/) { s/\s+.*//; s/\./_/g; }' "$prot_work"
    cmd+=("--prot_seq=${prot_work}" --etpmode)
elif [[ "$SKIP_ETP" == "1" ]]; then
    echo "[run] SKIP_ETP=1 → 仅 RNA-seq（BRAKER ET 风格，无 --etpmode）"
elif [[ -z "$PROT_SEQ" ]]; then
    echo "[run] 未设 PROT_SEQ → 仅 RNA-seq"
fi

printf '  + %s\n' "${cmd[*]}"
"${cmd[@]}"

gtf_in="${WORKINGDIR}/braker.gtf"
[[ -f "$gtf_in" ]] || { echo "[ERROR] 未找到输出 $gtf_in" >&2; exit 1; }

# 教学后处理：CDS→exon 复制；去掉 transcript/gene/intron/# 行
perl -e '
  while (<>) {
    if (m/\tCDS\t/) { print; s/\tCDS\t/\texon\t/; print; }
    elsif (m/\ttranscript\t/) { next; }
    elsif (m/^#/) { next; }
    elsif (m/\tgene\t/) { next; }
    elsif (m/\tintron\t/) { next; }
    else { print; }
  }
' "$gtf_in" > braker.gtf

if command -v gtf2gff3.pl >/dev/null 2>&1; then
    gtf2gff3.pl braker.gtf > braker.gff3
elif command -v gtf2gff.pl >/dev/null 2>&1; then
    # 部分 AUGUSTUS/BRAKER 包提供 gtf2gff.pl
    gtf2gff.pl < braker.gtf > braker.gff3
else
    echo "[WARN] 未找到 gtf2gff3.pl / gtf2gff.pl；保留 braker.gtf，请自行转 GFF3" >&2
fi

if [[ -f braker.gff3 ]] && command -v gff3_clear.pl >/dev/null 2>&1; then
    gff3_clear.pl --prefix "$GFF3_PREFIX" braker.gff3 > braker.gff3.tmp
    mv braker.gff3.tmp braker.gff3
fi

if [[ -f braker.gff3 ]]; then
    echo "[run] 完成：${WORKINGDIR}/braker.gtf → braker.gtf → braker.gff3"
else
    echo "[run] 完成：${WORKINGDIR}/braker.gtf → braker.gtf"
fi
