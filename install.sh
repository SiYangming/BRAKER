#!/usr/bin/env bash
# =============================================================================
# install.sh — BRAKER2 宿主机安装（通用）
#
# 归属：https://github.com/SiYangming/BRAKER （本 fork；见 INSTALL.md）
# 来源整理：教学 software_installation.sh 中 BRAKER 段 + bioconda / 官方 tarball
#
# 路线：
#   - conda（默认优先）：mamba/conda 建独立 env，pin bioconda::braker2
#   - binary（无 conda 兜底）：GitHub tag tarball（纯 Perl）部署到 --prefix
# 版本默认 2.1.5（教学锚点；可 --version 覆盖）
#
# 官方来源（勿依赖本地 BRAKER-*.tar.gz；tag 即可复现）：
#   https://github.com/Gaius-Augustus/BRAKER/archive/refs/tags/v2.1.5.tar.gz
#   本 fork 同 tag：https://github.com/SiYangming/BRAKER/archive/refs/tags/v2.1.5.tar.gz
#   bioconda：https://anaconda.org/bioconda/braker2
#   容器：quay.io/biocontainers/braker2
#
# 依赖：AUGUSTUS / GeneMark-ES/ET / ProtHint / GenomeThreader / samtools /
#   bamtools / ncbi-rmblast / diamond 等；GeneMark 需 ~/.gm_key。
#   binary 仅装 BRAKER 脚本；推荐 conda 路线自动带依赖。
#
# 可选补丁（教学常见失败点）：
#   --patch-augustus PATH  将 augustus/.../filterGenesIn_mRNAname.pl 中
#   transcript_id 捕获改为非贪婪 (.*?)，避免 braker 产出空文件。
#
# 用法：
#   bash install.sh
#   bash install.sh --method conda
#   bash install.sh --method binary --prefix ~/software/braker-2.1.5
#   bash install.sh --patch-augustus "$AUGUSTUS_CONFIG_PATH/../scripts"
#   bash install.sh --version 2.1.6 --force
# =============================================================================
set -euo pipefail

DEFAULT_VERSION="2.1.5"
VERSION="$DEFAULT_VERSION"
PREFIX="${PREFIX:-$HOME/software/braker-$DEFAULT_VERSION}"
CONDA_ENV="braker"
METHOD="auto"          # auto | conda | binary
PROFILE="${HOME}/.bashrc"
UPDATE_PATH=1
FORCE=0
PATCH_AUGUSTUS_SCRIPTS=""

log()  { printf '\033[1;32m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[install] 错误：%s\033[0m\n' "$*" >&2; exit 1; }

usage() {
    sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)     VERSION="${2:?}"; shift 2 ;;
        --prefix)      PREFIX="${2:?}"; shift 2 ;;
        --method)      METHOD="${2:?}"; shift 2 ;;
        --conda-env)   CONDA_ENV="${2:?}"; shift 2 ;;
        --profile)     PROFILE="${2:?}"; shift 2 ;;
        --patch-augustus) PATCH_AUGUSTUS_SCRIPTS="${2:?}"; shift 2 ;;
        --force)       FORCE=1; shift ;;
        --no-path-update) UPDATE_PATH=0; shift ;;
        --help|-h)     usage ;;
        *) die "未知参数: $1（--help 查看用法）" ;;
    esac
done

case "$METHOD" in auto|conda|binary) ;; *) die "--method 仅支持 auto|conda|binary" ;; esac

OS="$(uname -s)"; ARCH="$(uname -m)"
CONDA_BIN=""
if command -v mamba >/dev/null 2>&1; then CONDA_BIN="$(command -v mamba)"
elif command -v conda >/dev/null 2>&1; then CONDA_BIN="$(command -v conda)"; fi

assert_version() {
    local bin="$1" out
    out="$("$bin" --version 2>&1 | head -n 2 || true)"
    printf '  %s\n' "$out"
    grep -qE "${VERSION//./\.}" <<<"$out" || die "版本校验失败：期望包含 ${VERSION}"
    log "版本校验通过：$VERSION"
}

# 教学补丁：filterGenesIn_mRNAname.pl transcript_id 贪婪匹配会导致空结果
patch_augustus_filter() {
    local scripts_dir="$1"
    local target="$scripts_dir/filterGenesIn_mRNAname.pl"
    [[ -f "$target" ]] || die "未找到 $target（--patch-augustus 应指向 augustus scripts 目录）"
    perl -p -i -e 's#\(\.\*\)#\(\.\*\?\)# if m/transcript_id/;' "$target"
    log "已补丁：$target（transcript_id 捕获改为非贪婪）"
}

install_conda() {
    local env_exists
    log "conda 安装 braker2=$VERSION → env: $CONDA_ENV"
    env_exists="$("$CONDA_BIN" env list | awk -v e="$CONDA_ENV" '$1==e {print $1}')"
    if [[ -n "$env_exists" ]]; then
        if [[ "$FORCE" == 1 ]]; then
            log "环境 $CONDA_ENV 已存在（--force），删除重建"
            "$CONDA_BIN" env remove -y -n "$CONDA_ENV"
        else
            die "conda 环境 $CONDA_ENV 已存在；加 --force 或换 --conda-env"
        fi
    fi
    if [[ "$(basename "$CONDA_BIN")" == "mamba" ]]; then
        mamba create -y -n "$CONDA_ENV" -c conda-forge -c bioconda "braker2=$VERSION"
    else
        conda create -y -n "$CONDA_ENV" -c conda-forge -c bioconda "braker2=$VERSION"
    fi
    log "验证：conda run -n $CONDA_ENV braker.pl --version"
    "$CONDA_BIN" run -n "$CONDA_ENV" braker.pl --version 2>&1 | head -n 2 | sed 's/^/  /' || true
    log "完成：conda activate $CONDA_ENV 后可用 braker.pl"
}

install_binary() {
    local url tmp srcdir dest
    url="https://github.com/Gaius-Augustus/BRAKER/archive/refs/tags/v${VERSION}.tar.gz"
    dest="$PREFIX"
    log "下载官方源码（纯 Perl）：$url"
    warn "binary 仅部署 BRAKER 脚本；AUGUSTUS/GeneMark/ProtHint/gth 等需另行安装"
    log "安装前缀: $dest"

    tmp="$(mktemp -d)"
    cleanup_tmp() { [[ -n "${tmp:-}" ]] && rm -rf "$tmp"; }
    trap cleanup_tmp EXIT

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$tmp/braker.tar.gz" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmp/braker.tar.gz" "$url"
    else
        die "需要 curl 或 wget"
    fi
    tar -xzf "$tmp/braker.tar.gz" -C "$tmp"
    srcdir="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d -name "BRAKER-*" | head -1)"
    [[ -n "$srcdir" ]] || die "解压目录异常（URL/版本？）"

    mkdir -p "$dest"
    # 持久化源码树后再软链，避免删 tmp 后断链
    rm -rf "$dest/BRAKER-${VERSION}"
    cp -a "$srcdir" "$dest/BRAKER-${VERSION}"
    mkdir -p "$dest/bin"
    local found=0
    for exe in "$dest/BRAKER-${VERSION}"/scripts/*; do
        [[ -f "$exe" ]] || continue
        ln -sfn "$exe" "$dest/bin/$(basename "$exe")"
        found=1
    done
    [[ "$found" == 1 ]] || die "scripts/ 下未找到脚本"
    rm -rf "$tmp"; tmp=""; trap - EXIT

    # 与教学脚本一致的 Perl 依赖（binary 路线；conda 通常已带）
    if command -v cpan >/dev/null 2>&1; then
        log "安装常用 Perl 模块（Scalar::Util::Numeric MCE::Mutex Math::Utils）"
        cpan -i Scalar::Util::Numeric MCE::Mutex Math::Utils || \
            warn "cpan 安装失败时可手动：cpan -i Scalar::Util::Numeric MCE::Mutex Math::Utils"
    else
        warn "未找到 cpan；若缺 Perl 模块请自行安装"
    fi

    assert_version "$dest/bin/braker.pl"

    if [[ "$UPDATE_PATH" == 1 ]]; then
        local line="export PATH=\"$dest/bin:\$PATH\""
        if [[ -f "$PROFILE" ]] && grep -qF "$dest/bin" "$PROFILE"; then
            log "PATH 已含 $dest/bin，跳过写入 $PROFILE"
        else
            { echo ""; echo "# braker (SiYangming/BRAKER install.sh)"; echo "$line"; } >> "$PROFILE"
            log "已追加 PATH 到 $PROFILE"
        fi
        log "完成：source $PROFILE 后执行 braker.pl"
    else
        log "完成（未改 PATH）：export PATH=\"$dest/bin:\$PATH\""
    fi
}

log "braker $VERSION 安装开始（${OS}/${ARCH}）"
case "$METHOD" in
    conda)
        [[ -n "$CONDA_BIN" ]] || die "--method conda 但未检测到 mamba/conda"
        install_conda ;;
    binary)
        install_binary ;;
    auto)
        if [[ -n "$CONDA_BIN" ]]; then install_conda; else install_binary; fi ;;
esac

if [[ -n "$PATCH_AUGUSTUS_SCRIPTS" ]]; then
    patch_augustus_filter "$PATCH_AUGUSTUS_SCRIPTS"
fi

log "安装成功"
