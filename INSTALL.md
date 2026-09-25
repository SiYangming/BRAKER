# BRAKER 安装

本 fork 附加安装说明与运行示例；上游源码与 BRAKER4 仍见：

- 上游：<https://github.com/Gaius-Augustus/BRAKER>
- BRAKER4：<https://github.com/Gaius-Augustus/BRAKER4>
- 运行示例：[example.md](example.md)

bioskills **不入库** tarball；教学压缩包在本仓 Release：

| 资源 | Release |
|------|---------|
| `BRAKER-2.1.5.tar.gz` | [v2.1.5](https://github.com/SiYangming/BRAKER/releases/tag/v2.1.5) |
| `BRAKER1_v1.8.tar.gz` | [BRAKER1_v1.8](https://github.com/SiYangming/BRAKER/releases/tag/BRAKER1_v1.8) |

版本锚点：**2.1.5**（bioconda `braker2`）。binary 路线仅装 BRAKER 脚本；还需 AUGUSTUS、GeneMark（`~/.gm_key`）、ProtHint、GenomeThreader、samtools、bamtools、ncbi-rmblast、DIAMOND 等（见上游 README）。

---

## 路线 A：conda（推荐）

```bash
mamba create -y -n braker -c conda-forge -c bioconda braker2=2.1.5
conda activate braker
braker.pl --version
```

容器：`quay.io/biocontainers/braker2:2.1.5--hdfd78af_3`

---

## 路线 B：tarball（纯 Perl）

```bash
VERSION=2.1.5
PREFIX="$HOME/software/braker-${VERSION}"
mkdir -p "$PREFIX"
curl -fsSL -o /tmp/BRAKER-${VERSION}.tar.gz \
  -L "https://github.com/SiYangming/BRAKER/releases/download/v${VERSION}/BRAKER-${VERSION}.tar.gz"
# 或官方 tag：
# https://github.com/Gaius-Augustus/BRAKER/archive/refs/tags/v${VERSION}.tar.gz

tar -xzf /tmp/BRAKER-${VERSION}.tar.gz -C "$PREFIX"
# Release 资产解压为 BRAKER-2.1.5/；官方 tag 包同名
echo "export PATH=\"$PREFIX/BRAKER-${VERSION}/scripts:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

# Perl 依赖（教学安装段）
cpan -i Scalar::Util::Numeric MCE::Mutex Math::Utils
braker.pl --version
```

---

## AUGUSTUS 补丁（教学常见失败点）

`filterGenesIn_mRNAname.pl` 中 `transcript_id` 贪婪匹配会导致 braker 产出空文件：

```bash
perl -p -i -e 's#\(\.\*\)#\(\.\*\?\)# if m/transcript_id/;' \
  "${AUGUSTUS_SCRIPTS_PATH:-$AUGUSTUS_CONFIG_PATH/../scripts}/filterGenesIn_mRNAname.pl"
```

---

## 历史：BRAKER1 v1.8

仅 RNA-seq；上游无对应 tag。见 [Release BRAKER1_v1.8](https://github.com/SiYangming/BRAKER/releases/tag/BRAKER1_v1.8)。新流程用 BRAKER2+ 或 BRAKER4。

```bash
curl -fsSL -L -o BRAKER1_v1.8.tar.gz \
  https://github.com/SiYangming/BRAKER/releases/download/BRAKER1_v1.8/BRAKER1_v1.8.tar.gz
tar zxf BRAKER1_v1.8.tar.gz
export PATH="$PWD/BRAKER_v1.8:$PATH"
braker.pl --species=NAME --genome=genome.fa --bam=rnaseq.bam
```
