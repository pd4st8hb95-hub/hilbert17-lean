# 希尔伯特第十七问题的 Lean 形式化

**希尔伯特第十七问题已在 Lean 4.32.1 中得到形式化证明。本次内置依赖源码版本已通过全部 3,136 个选定模块的干净离线重建、四个聚合目标及最终 no-build 最新状态检查；14 条验收类型输出和 14 条递归公理记录与此前核验结果一致，公理依赖只含三项标准经典公理。**

本版把这 97 个配置入口所需的完整外部 Lean 源文件导入闭包一并放入仓库：**8 个固定版本的依赖包，共 3,039 个 Lean 文件，其中 Mathlib 2,775 个，其余 7 个包合计 264 个**。原有项目证明源文件保持不变，所有有效依赖配置都使用 `vendor/` 下的相对本地路径。

**针对本版新产物的 fresh 导入环境重放：通过。** 2026-10-13 的 `vendor-fresh02` 运行执行 `leanchecker --fresh -v BoundaryAcceptance`，耗时 **515.567 秒**，退出码为 0。其导入闭包覆盖已构建 **3,136 个项目／外部依赖模块中的 3,131 个**，以及所导入的工具链环境；所有载入的安全、非 partial 常量均由同一 Lean 内核重新检查。全部固定输入与产物哈希保持不变。重放仍接纳公理声明，因此递归公理审计单独保留。

## 证明的命题

对任意自然数 `n` 和任意实系数多项式 `f : MvPolynomial (Fin n) ℝ`，若它在每个实点都非负，则它在同一个多项式环的分式域中是有限个平方之和：

```lean
∀ (n : ℕ) (f : MvPolynomial (Fin n) ℝ),
  (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) →
  IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
    (FractionRing (MvPolynomial (Fin n) ℝ)) f)
```

等价地，存在有限个实系数多项式 `p i` 及非零多项式 `q`，使

```lean
q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2
```

这里没有次数上界、正变量数、严格正性或有理系数限制。包括 `n = 0`、零多项式和空平方和。分母只须作为多项式非零，允许在个别实点为零；必要性证明也覆盖这些点。

最终声明是 `Hilbert17Transfer.hilbert17Real_candidate` 和 `Hilbert17Transfer.hilbert17RealCleared_candidate`。原先条件版本需要的 `NegativePointTransfer` 已由有序实闭包与有限变量符号转移证明提供，最终定理不再保留该假设。

## 本版依赖源码重建核验

受保护的 `source01` 第 1 次运行于 **2026-10-13 19:33:12 UTC** 完成，状态为 `ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS`。从没有依赖编译产物的状态开始，3,039 个外部模块和 97 个项目模块均由固定源码重新编译，关闭本地编译缓存复用并禁止构建进程联网。四个聚合目标和最终 `--no-build` 检查均通过，全部固定源码、配置和资源输入保持不变。已安装的 Lean／Std／Lake 工具链仍被复用，本流程没有从源码重建 Lean 本身。

另行提取的验收输出审计状态为 `FOURTEEN_TYPES_AND_AXIOM_FOOTPRINTS_MATCH_PRIOR`：14 条定理类型输出在归一化空白后与此前核验结果相同，14 条递归公理记录均恰好包含 `propext`、`Classical.choice` 和 `Quot.sound`。这些是本次重新编译时产生的真实输出；提取审计本身不另行执行 Lean，也不能替代另行完成的新产物导入环境重放。

首次重放尝试因显式设置为空的搜索路径变量产生尾部空项，在环境预检时停止，尚未启动检查器。移除这两个空变量后，原有严格路径检查保持不变，重新固定计划的第二次运行通过。[本版验证报告](verification/vendored-source-20261013/VERIFICATION.md)保留两次记录并说明修正。

新证据的精确 SHA256：

- [源码构建计划](verification/vendored-source-20261013/source-build-plan01.json)：`c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460`
- [构建回执](verification/vendored-source-20261013/source-summary.json)：`437f5a86d3b5b46822f9a15672a7128109940bc17d1450309835a7e7e27b039d`
- [验收输出审计](verification/vendored-source-20261013/vendor-acceptance-audit01.json)：`dedd575f4975cd2533cb0250c436ddbbc0a3831fd1fc7b7aa0a7dd59d363ae16`
- [Fresh 重放计划](verification/vendored-source-20261013/vendor-fresh-plan02.json)：`6233bed408866c19a425870588c83329fe8464d4ba99c8c2bc97ba6c4ab439b2`
- [Fresh 重放回执](verification/vendored-source-20261013/replay-summary.json)：`c1a42cc27a79908d17f0f1692c4ba0f6debee066fcc15aacee0f6d2fcb2efb75`

## 历史上已核验的范围

- 完整定理、显式有限平方和验收，以及零变量、零多项式和充要条件验收均已编译通过
- 三个诊断模块中的 **17 条递归公理依赖记录，涉及 14 个不同声明**，只包含标准的 `propext`、`Classical.choice`、`Quot.sound`
- **97 个选定本地模块**重放全部通过：90 个最终证明依赖模块、2 个附加自检／必要性模块、2 个验收模块和 3 个导入入口；源文件与产物哈希已核对

上述重放使用同一固定版本的 Lean 内核，并导入当时已有的官方依赖。这不是外部独立验证器，也不表示重新重放了全部传递依赖中的 Mathlib 声明。历史可移植离线 Lake 的 306 条命令全部通过，并核对了两个验收模块实际输出的类型与 14 条不同声明的递归公理记录。该验证使用固定版本的本地官方源文件／缓存副本及命令级路径覆盖；它的范围保持不变，不因本版加入依赖源码而被改称为全部依赖源码重建。

详见[最终验证状态](verification/FINAL-STATUS.md)、[独立核验](verification/FINAL-INDEPENDENT-AUDIT01.json)、[97 模块重放核验](verification/FINAL-REPLAY-INDEPENDENT-AUDIT01.json)、[完整验收](checks/FinalTargetContract.lean)及[边界与充要条件验收](checks/BoundaryAcceptance.lean)。

## 离线源码复现

先单独安装 **Lean 4.32.1**，包括随工具链提供的 Lean、Std、Lake 库和 `leanchecker`。根目录工具链固定为 `leanprover/lean4:v4.32.1`，内置 Mathlib 源码提交为 `520045ab14e26149ee970e2e617ca04b09bde5d6`。工具链已安装且仓库文件完整后，在仓库根目录执行：

```sh
lake build Hilbert17 Hilbert17RealClosure Hilbert17Full Hilbert17Acceptance
lake env lean checks/FinalTargetContract.lean
lake env lean checks/BoundaryAcceptance.lean

# 更强的导入环境重放：构建完成后执行，可能需要更多时间与内存
lake env leanchecker --fresh -v BoundaryAcceptance
```

不需要联网拉取依赖、下载 Mathlib 编译缓存、安装 npm 包或构建 JavaScript。交付内容不包含依赖编译缓存；干净构建会从仓库内的源码编译选定的项目和外部依赖模块。已安装的 Lean／Std／Lake 是明确保留的工具链边界，本流程不从源码重建 Lean 本身。上游依赖各自的工具链文件作为来源资料保留，其中部分版本较旧，因此请始终从仓库根目录调用已安装的 4.32.1 工具链。

这些是复现指令，本版实际构建结果单独列在开头。普通聚合 `lake build` 可能同时调度多个模块；每个 Lean 进程的 `-j 1 -M 4096` 不等于全局串行。下面的串行方式可减少同时运行的编译任务；`--fresh` 也需要额外时间和内存。产物写入本地 `.lake/` 和 `vendor/*/.lake/`，依赖配置使用可移植的相对路径；历史回执保留原运行环境路径以便核对。

### 可移植的串行构建方式

[串行辅助脚本](scripts/build_serial.py)需要 **Python 3.11 或更新版本**。在仓库根目录执行，并按本机安装情况选择 Python 命令。第一条命令只核对源码／资源哈希、本地依赖配置和 3,136 个模块的依赖顺序，输出 JSON 计划，不启动 Lean 或 Lake：

```sh
python3.11 scripts/build_serial.py --check-plan
python3.11 scripts/build_serial.py
```

第二条命令按依赖顺序逐个构建模块，最后检查全部四个聚合目标。脚本寻找已经直接安装的工具链并核对 Lean 版本，不负责安装工具链。也可明确指定已安装的 Lake：

```sh
python3.11 scripts/build_serial.py --lake "/absolute/path/to/lean-4.32.1/bin/lake"
```

Windows 可使用本机 Python 3.11+ 的启动命令，例如 `py -3.11`，并指定工具链内的 `lake.exe`。串行构建后，仍须使用同一套已安装的 Lean 4.32.1 工具链执行上面两个验收源文件检查和 `--fresh` 重放命令。

辅助脚本可以复用已有本地产物，没有 Linux seccomp 网络隔离、整机内存保护或完整编译产物审计；成功信息只表示配置目标已是最新状态。它的 3,136 模块计划和命令顺序已与受保护构建计划做静态比对，脚本本身尚未单独端到端运行。完整的从源码重建证据来自另行执行的干净、受保护构建及其核验回执，状态见本文开头；不能把一次辅助脚本成功等同于该项更强审计。

`Hilbert17Full` 是完整证明入口；`Hilbert17` 和 `Hilbert17RealClosure` 保留早期阶段的入口。声明名中的 `_candidate` 及部分文件头的 “source-only” 等文字是历史标记。为保持已检查源文件的字节不变，这些文字未被改写；实际验证状态应以注明范围和哈希的最终回执为准。

## 内置依赖与界面资源

8 个依赖包分别为 Mathlib、Batteries、Qq、Aesop、ProofWidgets、ImportGraph、LeanSearchClient 和 Plausible。收录的是所有配置入口传递导入的完整文件，包括所需策略和检查基础设施；不是各上游仓库的全量镜像，也不是逐条声明裁剪后的最小集合。全部 3,039 个依赖 Lean 文件都与固定提交的上游 Git blob 字节一致，原版权头、作者、许可和原始配置保留。

详见[依赖源码清单](vendor-source-manifest.json)、[依赖目录说明](vendor/README.md)、[离线构建配置适配](VENDORED-BUILD-CONFIG.md)和[第三方说明](THIRD_PARTY.md)。

同时收录 15 个编译时读取的文本／JavaScript 资源，其中 14 个与固定上游字节一致。可选的 Penrose 图形展示使用一个明确记录的无图形适配文件，编辑器中的相应图形渲染被禁用，改为显示说明文字。数学证明的 Lean 源码和定理陈述均未改动，也没有因此添加证明公理。本次已通过的源码重建和 fresh 导入环境重放均包含由这一资源变化生成的新产物。本版不是完整的上游交互图形界面构建。详见[资源清单](vendor-asset-manifest.json)。

## 来源与署名

本项目形式化的是经典定理，使用并适配了带署名的 TauCeti 与 Mathlib 基础设施，并补充本地连接证明和兼容性证明；不声称数学创新或首次形式化。

TauCeti 来源固定为提交 `6b896c7c411221eb78639e4be8ead6e479a62893`。部分兼容模块取自较新的官方 Mathlib 提交 `3b531c35df33d6bbe64b4e87dec056211d3a5676`，再适配到上述固定工具链。原作者、逐文件版权头、Apache 2.0 许可、原始快照及改动来源均保留，详见[第三方说明](THIRD_PARTY.md)和[证明路线](PROOF-MAP.md)。上游许可的保留不等于为本地原创部分另行指定统一许可。

详见历史 [Lake 集成回执](verification/PORTABLE-LAKE-STATUS.md)。首次尝试在证明构建前因依赖覆盖 JSON 格式不符而失败，修正后第二次通过；两次记录均保留。历史额外的 `--fresh` 安全、非 partial 导入环境重放（包括所用 Mathlib 证明）已退出 0，通过核验。递归公理依赖检查已排除最终定理中的未证明外部数学假设，但它与逐条从头重检所有导入常量是不同的验证层次。这些历史记录不改写为本版新产物的核验结果。

## 外部数学结论的形式化证明

[外部结论证明说明](EXTERNAL-INGREDIENT-PROOFS.md)及[来源映射](EXTERNAL-INGREDIENT-MAP.json)列出 49 项主要来源条目、83 个 Lean 声明。所用结论由 Lean 证明体提供；文献引用用于背景与署名，不是额外公理。中间定理的实闭性、Rolle 性质、矩阵可逆性及转移假设均在最终组装中得到证明。

历史 [Fresh 重放回执](verification/FRESH-REPLAY-STATUS.md)记录 `leanchecker --fresh -v BoundaryAcceptance` 在 526.513 秒后退出 0，标准错误为空。检查把最终入口及其导入环境中的安全、非 partial 声明重新送入同一版本 Lean 内核的空环境；不声称使用外部独立内核，也不声称检查了安装目录中所有无关 Mathlib 模块。重放机制仍接纳公理声明，因此最终定理仅依赖三项标准公理的递归审计仍单独保留。
