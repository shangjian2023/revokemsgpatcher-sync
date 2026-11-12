# revokemsgpatcher-sync

定时把 [shangjian2023/RevokeMsgPatcher](https://github.com/shangjian2023/RevokeMsgPatcher)
（fork）从上游 [huiyadanli/RevokeMsgPatcher](https://github.com/huiyadanli/RevokeMsgPatcher)
快进同步。

## 为什么单独建这个仓库

不在 fork 内部放定时任务，有三个硬伤：

1. **fork 里所有 workflow 默认是禁用的**，得手动去 Actions 页面一个个启用，而且后续可能被平台重新禁用。
2. **schedule 只在默认分支上生效**。如果把 workflow 提交到 fork 的 `master`，`master` 就不再等同于上游，
   快进同步的前提（fork 是上游的纯子集）被破坏，循环自证失败。
3. **公开仓库 60 天无活动会自动禁用定时任务**。上游一年才发几个版本，fork 长期静默，
   定时任务会在某天悄悄失效，只在 Actions 日志里留个记录。

放在这个独立仓库里就没有以上问题——它是你自己的普通仓库，schedule 稳定触发，
且通过 PAT 有权 push 到 fork。

## 配置

| 类型 | 名称 | 值 |
|---|---|---|
| secret | `FORK_SYNC_TOKEN` | 具备 `public_repo` scope 的 PAT |
| variable | `FORK_REPO` | `shangjian2023/RevokeMsgPatcher` |
| variable | `UPSTREAM_REPO` | `huiyadanli/RevokeMsgPatcher` |
| variable | `BRANCH` | `master` |

## 行为约定

* 只做 `--ff-only` 快进，**永不 force push、永不制造 merge commit**
* fork 若产生了自己的提交导致分叉，任务会**失败退出并打印分叉图**，而不是强行覆盖
* 已同步时直接退出，不产生无意义提交（顺带保持仓库"有活动"，规避 60 天自动禁用）
* cron 设为 `23 4 * * *`（UTC），刻意避开整点高峰

## 手动触发

Actions → Sync fork with upstream → Run workflow。
