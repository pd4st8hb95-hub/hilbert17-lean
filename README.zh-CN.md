# 希尔伯特第十七问题的 Lean 形式化

**完整目标及验收声明已通过编译；递归公理依赖检查和 97 个选定本地模块的内核重放均通过。可移植离线 Lake 集成验证也已通过；额外的完整导入环境 fresh 重放仍在单独推进。**

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

## 已核验的范围

- 完整定理、显式有限平方和验收，以及零变量、零多项式和充要条件验收均已编译通过
- 三个诊断模块中的 **17 条递归公理依赖记录，涉及 14 个不同声明**，只包含标准的 `propext`、`Classical.choice`、`Quot.sound`
- **97 个选定本地模块**重放全部通过：90 个最终证明依赖模块、2 个附加自检／必要性模块、2 个验收模块和 3 个导入入口；源文件与产物哈希已核对

重放使用同一固定版本的 Lean 内核，并导入既有官方依赖。这不是外部独立验证器，也不表示重新重放了全部传递依赖中的 Mathlib 声明。可移植离线 Lake 的 306 条命令全部通过，并核对了两个验收模块实际输出的类型与 14 条不同声明的递归公理记录。该验证使用固定版本的本地官方源文件／缓存副本及命令级路径覆盖，不代表全新联网检出或重建全部依赖。

详见[最终验证状态](verification/FINAL-STATUS.md)、[独立核验](verification/FINAL-INDEPENDENT-AUDIT01.json)、[97 模块重放核验](verification/FINAL-REPLAY-INDEPENDENT-AUDIT01.json)、[完整验收](checks/FinalTargetContract.lean)及[边界与充要条件验收](checks/BoundaryAcceptance.lean)。

## 复现

固定工具链为 `leanprover/lean4:v4.32.1`，Mathlib 提交为 `520045ab14e26149ee970e2e617ca04b09bde5d6`。工具链可用后，在仓库根目录执行：

```sh
# 可选：下载 Mathlib 官方编译缓存，需要联网
lake exe cache get

lake build Hilbert17 Hilbert17RealClosure Hilbert17Full Hilbert17Acceptance
lake env lean checks/FinalTargetContract.lean
lake env lean checks/BoundaryAcceptance.lean
```

这些是复现指令，不是“已从全新联网检出完成构建”的声明。也可不下载缓存而自行构建依赖。交付内容不包含编译缓存，构建配置不使用本机依赖绝对路径；历史核验回执保留原运行环境路径以便核对。

`Hilbert17Full` 是完整证明入口；`Hilbert17` 和 `Hilbert17RealClosure` 保留早期阶段的入口。声明名中的 `_candidate` 及部分文件头的 “source-only” 等文字是历史标记。为保持已检查源文件的字节不变，这些文字未被改写；实际验证状态应以注明范围和哈希的最终回执为准。

## 来源与署名

本项目形式化的是经典定理，使用并适配了带署名的 TauCeti 与 Mathlib 基础设施，并补充本地连接证明和兼容性证明；不声称数学创新或首次形式化。

TauCeti 来源固定为提交 `6b896c7c411221eb78639e4be8ead6e479a62893`。部分兼容模块取自较新的官方 Mathlib 提交 `3b531c35df33d6bbe64b4e87dec056211d3a5676`，再适配到上述固定工具链。原作者、逐文件版权头、Apache 2.0 许可、原始快照及改动来源均保留，详见[第三方说明](THIRD_PARTY.md)和[证明路线](PROOF-MAP.md)。上游许可的保留不等于为本地原创部分另行指定统一许可。

详见 [Lake 集成回执](verification/PORTABLE-LAKE-STATUS.md)。首次尝试在证明构建前因依赖覆盖 JSON 格式不符而失败，修正后第二次通过；两次记录均保留。额外的 `--fresh` 完整安全导入环境重放（包括 Mathlib）仍待后续回执。当前递归公理依赖检查已排除最终定理中的未证明外部数学假设，但它与逐条从头重检所有导入常量是不同的验证层次。
