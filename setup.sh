#!/usr/bin/env bash
# 一键搭好：fork 上游 + 建同步仓库 + 配置 secret/variable + 推送 workflow
# 用法： bash setup.sh
set -euo pipefail

FORK_REPO="${FORK_REPO:-shangjian2023/RevokeMsgPatcher}"
UPSTREAM_REPO="${UPSTREAM_REPO:-huiyadanli/RevokeMsgPatcher}"
SYNC_REPO="${SYNC_REPO:-shangjian2023/revokemsgpatcher-sync}"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "==> 检查 gh 登录状态"
gh auth status

echo "==> 检查 token 是否有 public_repo 权限"
if ! gh api user --jq '.login' >/dev/null 2>&1; then
  echo "!! gh 未登录或 token 无效，请先执行： gh auth refresh -h github.com -s public_repo"
  exit 1
fi

echo "==> 创建 fork: ${FORK_REPO}"
if gh repo view "$FORK_REPO" >/dev/null 2>&1; then
  echo "   fork 已存在，跳过"
else
  gh repo fork "$UPSTREAM_REPO" --clone=false
fi

echo "==> 创建同步仓库: ${SYNC_REPO}"
if gh repo view "$SYNC_REPO" >/dev/null 2>&1; then
  echo "   已存在，跳过创建"
else
  gh repo create "$SYNC_REPO" --public --description "定时快进同步 RevokeMsgPatcher fork" --add-readme
fi

echo "==> 配置 repository variables"
gh variable set FORK_REPO     --repo "$SYNC_REPO" --body "$FORK_REPO"
gh variable set UPSTREAM_REPO --repo "$SYNC_REPO" --body "$UPSTREAM_REPO"
gh variable set BRANCH        --repo "$SYNC_REPO" --body "master"

echo "==> 配置 secret FORK_SYNC_TOKEN"
TOKEN="$(gh auth token)"
gh secret set FORK_SYNC_TOKEN --repo "$SYNC_REPO" --body "$TOKEN"

echo "==> 推送 workflow"
cd "$HERE"
if gh repo view "$SYNC_REPO" >/dev/null 2>&1; then
  git init -q 2>/dev/null || true
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${SYNC_REPO}.git"
  git add -A
  git -c user.name="shangjian2023" -c user.email="2045306963@qq.com" commit -q -m "Add scheduled fork sync workflow" || true
  git push -q origin HEAD:main 2>&1 | tail -5 || git push -q origin HEAD:master
fi

echo
echo "完成。"
echo "  fork      : https://github.com/${FORK_REPO}"
echo "  sync repo : https://github.com/${SYNC_REPO}"
echo "  手动验证  : gh workflow run sync-fork.yml --repo ${SYNC_REPO}"
