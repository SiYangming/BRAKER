# BRAKER 安装与运行（通用配方）

本文件与同目录 `install.sh` / `run.sh` 归属 **SiYangming/BRAKER** fork，
从教学流水线 `software_installation.sh` / `run.sh` 蒸馏而来，去掉 `/opt/biosoft`、`/home/train` 等硬编码。

bioskills 只保留链接，**不入库**本地 `BRAKER-*.tar.gz`。

| 资源 | 结论 |
|------|------|
| `BRAKER-2.1.5.tar.gz` | 与官方 tag 字节级一致，用 GitHub 下载即可 |
| `BRAKER1_v1.8.tar.gz` | 上游无对应 tag；脚本已放入 `legacy/BRAKER_v1.8/`（历史参考，默认不用） |

上游：<https://github.com/Gaius-Augustus/BRAKER>  
本 fork：<https://github.com/SiYangming/BRAKER>（与上游 master 同步；本仓附加安装/运行配方）  
BRAKER4（推荐新项目）：<https://github.com/Gaius-Augustus/BRAKER4>

---

## 版本锚点

- **BRAKER2**：`2.1.5`（bioconda `braker2`；教学原用此版）
- 亦可：`v2.1.6` / 当前 master（BRAKER3 能力）；与 BRAKER4 **不直接互换**

```bash
# 官方可复现源码（勿依赖本地 tar）
curl -fsSL -o BRAKER-2.1.5.tar.gz \
  https://github.com/Gaius-Augustus/BRAKER/archive/refs/tags/v2.1.5.tar.gz
# 或本 fork 同 tag：
# https://github.com/SiYangming/BRAKER/archive/refs/tags/v2.1.5.tar.gz
```

---

## 安装（`install.sh`）

```bash
# conda（推荐，带依赖）
bash install.sh --method conda
# 或官方 tarball → 前缀（仅 BRAKER 脚本；AUGUSTUS/GeneMark 等需另装）
bash install.sh --method binary --prefix ~/software/braker-2.1.5 --version 2.1.5

# 教学常见补丁：AUGUSTUS filterGenesIn_mRNAname.pl 贪婪匹配会导致空结果
bash install.sh --patch-augustus "$AUGUSTUS_CONFIG_PATH/../scripts"
# 等价手工：
# perl -p -i -e 's#\(\.\*\)#\(\.\*\?\)# if m/transcript_id/;' \
#   /path/to/augustus/scripts/filterGenesIn_mRNAname.pl
```

binary 路线会安装常用 Perl 模块：`Scalar::Util::Numeric` `MCE::Mutex` `Math::Utils`。

**运行依赖（binary 需自备）**：AUGUSTUS、GeneMark-ES/ET（`~/.gm_key`）、ProtHint、GenomeThreader、samtools、bamtools、ncbi-rmblast、DIAMOND 等。详见上游 README。

---

## 运行（`run.sh`）

ETP 风格：软屏蔽基因组 + RNA-seq BAM +（可选）同源蛋白。

```bash
export PATH=...   # 含 braker.pl；或 conda activate braker
# 可选依赖路径（有则传给环境，无则靠 PATH）
# export AUGUSTUS_CONFIG_PATH=... GENEMARK_PATH=... 等

GENOME=genome.softmask.fasta \
BAM=rnaseq.sort.bam \
PROT_SEQ=homolog.fasta \
SPECIES=myspecies_braker \
CORES=8 \
bash run.sh
```

仅 RNA-seq（无蛋白 / 跳过 etpmode）：

```bash
GENOME=... BAM=... SPECIES=... SKIP_ETP=1 bash run.sh
# 或不设 PROT_SEQ
```

后处理：从 `WORKINGDIR/braker.gtf` 生成工作区 `braker.gtf` / `braker.gff3`（需 `gtf2gff3.pl`；可选 `gff3_clear.pl`）。

---

## 历史：BRAKER1 v1.8

仅 RNA-seq；CentOS 6 教学曾用。源码见 [`legacy/BRAKER_v1.8/`](legacy/BRAKER_v1.8/)。新流程请用 BRAKER2+ 或 BRAKER4。

```bash
# 仅作考古；勿与 BRAKER2 混用 PATH
export PATH="/path/to/legacy/BRAKER_v1.8:$PATH"
braker.pl --species=NAME --genome=genome.fa --bam=rnaseq.bam
```
