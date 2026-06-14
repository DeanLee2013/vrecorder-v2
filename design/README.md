# Handoff: VRecorder MVP — 同声传译 iOS App（同传 + 设置）

## Overview

VRecorder 是一个同声传译 App：用户对着手机说话，通过 Claude / OpenAI 的流式 API 实时转写并翻译，双方各看各的语言。本交付包覆盖 **MVP 范围**：

1. **同声传译屏（主界面）** — App 启动直达的全屏双方分屏舞台
2. **设置屏** — 翻译引擎、语音播报、同传选项、通用

## About the Design Files

本包中的文件是 **HTML/JSX 设计参考稿**（高保真原型），不是可直接搬运的生产代码。你的任务是在 **iOS 原生环境（SwiftUI 优先）** 中按本文档重建这些界面，复用 iOS 既有惯例（SF Symbols、UIKit 动效、系统字体回退等）。打开 `design/mvp.html` 即可在浏览器中交互式预览两个屏幕（需要在本包根目录起一个静态服务器，或直接看本 README 的精确规格）。

## Fidelity

**High-fidelity。** 颜色、字号、间距、动效参数均为最终值，按像素还原。唯一的自由度：iOS 上可用系统字体（见 Design Tokens › 字体）。

## Screens / Views

### 1. 同声传译屏（LiveScreen — 主界面）

全屏，竖向两等分（`1fr / 1fr` grid）。**没有**导航栏。

**上半屏 — 对方（Party B，墨色）**
- 背景 `#07070C`（ink-950）。文字颜色 `#E9E9F2`（主）/ `#6B6B85`（暗）。
- 顶部一行（距顶 54pt，左右 inset 12pt，space-between）：
  - 左：齿轮 IconButton（40×40pt，ghost，色 `#6B6B85`）→ 打开设置
  - 中：`同传中` LiveBadge — 胶囊（圆角 999），背景 `rgba(43,217,200,0.14)`，文字 `#2BD9C8` 11pt bold 全大写 tracking 0.06em，左侧 6pt 呼吸圆点（vr-pulse 动画 1.6s）
  - 右：切换语言 IconButton（双向箭头图标）
- 内容底对齐（`justify-content: flex-end`），左右 padding 24pt，底部 28pt：
  - 语言标签 `ENGLISH` — 13pt，`#6B6B85`，tracking 0.06em
  - 字幕行（TranscriptLine，见 Components）

**下半屏 — 我方（Party A，紫色「水」）**
- 背景 `#5B3DF5`（violet-600）。这块面板是「杯中的水」。
- **水面（WaterSurface）**：面板顶边即水面，向上突出 44pt 高的波浪带（绝对定位 `bottom: 100%`，不挡内容、不可点击）。
  - 待机：近乎平直的静水线
  - 录音中：三层紫色填充波浪叠加（透明度 0.35 / 0.55 / 1.0，频率约 1.4–1.9 个周期，互相反向漂移），能量随时间缓慢起伏（约 0.7±0.3）模拟说话强弱
  - SwiftUI 实现建议：`TimelineView(.animation)` + `Canvas`，每层 path = 正弦叠加（主频 + 2.3 倍频 × 0.3），填充色同面板背景色 + 不同 opacity
- 内容（padding 28/24/0）：
  - 语言标签 `中文 · 普通话` — 13pt，`rgba(255,255,255,0.62)`
  - 录音但无内容时的提示 `请开始说话吧` — 22pt，白 62%，shimmer 闪烁（1.4s）
  - 字幕行（TranscriptLine）
- 底部中央（距底 30pt）：
  - **MicButton** 64×64pt 圆形：待机紫 `#7050FF` + 投影；录音时水青 `#2BD9C8` + 辉光 `0 0 0 6pt rgba(43,217,200,0.16), 0 0 28pt rgba(43,217,200,0.30)` + vr-pulse 呼吸（scale 1→1.08→1, 1.6s）；图标为麦克风线性图标（SF Symbol `mic` 即可），尺寸≈按钮的 36%
  - 其下 10pt：帮助文字 `为保证同传效果，请靠近麦克风说话` — 13pt，白 62%

### 2. 设置屏（SettingsScreen）

浅色主题（light scope token），iOS 分组列表样式。

- 背景 `#F7F7FB`（ink-50）。顶部 54pt 安全区 + 返回钮（chevron，紫 `#5B3DF5`）+ 大标题 `设置`（28pt bold）。
- 分组卡片：白底，圆角 16，阴影 `0 1px 4px rgba(12,12,20,0.08), 0 4px 16px rgba(12,12,20,0.06)`；行高 50pt，行间 hairline `rgba(12,12,20,0.08)`；组标题 13pt `#6B6B85` 置于卡片上方 8pt。
- 分组与行：
  | 组 | 行 | 控件 |
  |---|---|---|
  | 翻译引擎 | 翻译服务 | 值文本 `Claude` / `OpenAI`（detail + chevron，弹选择器） |
  | | API 密钥 | 值 `已配置`，chevron → 密钥录入页 |
  | | 流式翻译 | Switch（默认开） |
  | 语音播报 | 自动播报译文 | Switch（默认开） |
  | | 语速 | 值 `0.8× / 1.0× / 1.2×` |
  | 同声传译 | 字幕字号 | 值 `标准 / 大 / 特大` |
  | | 仅转写模式 | Switch（默认关） |
  | 通用 | 历史记录 | 值 `保留 30 天` |
  | | 清空翻译记录 | 红色 `#FF5C5C` 文字按钮（确认弹窗） |
  | | 关于 | 值 `版本 1.0.0` |
- Switch：iOS 原生 `Toggle`，tint = `#7050FF`。

## Interactions & Behavior

- **录音流程**：点击 MicButton → 进入 listening（按钮变水青、水面起波、LiveBadge 显示）→ 流式 API 返回 partial 字幕（22pt、62% 透明度、shimmer）→ 该句 final（30pt、semibold、全亮，带 250ms ease-out 的字号/颜色过渡）→ 旧行降级为 history（17pt、暗色）。每个面板最多保留约 3 行（旧行滚出）。再次点击 MicButton 停止。
- **partial → final 的节奏**是产品灵魂：partial 不断被替换（同一行原地更新），final 一次性提交并放大。
- **设置入口**：同传屏左上角齿轮 → push 设置屏；返回回到同传（会话状态保留）。
- **动效 token**：fast 150ms（按压/开关）、base 250ms（多数过渡）、slow 420ms（push/sheet）；缓动 ease-out `cubic-bezier(0.2,0,0,1)`，呼吸循环 `cubic-bezier(0.37,0,0.63,1)`。**永不弹跳**（no spring overshoot）。尊重「减弱动态效果」：水面静止为中等能量帧、shimmer/pulse 停止。
- **按压态**：不透明度或加深一档；无缩放回弹。

## State Management

- 会话状态机：`idle → listening → (partial*) → final → idle`；每方一个字幕数组 `[{status: partial|final|history, text}]`。
- 设置项持久化（UserDefaults / Keychain：API 密钥必须 Keychain）。
- 录音权限、网络失败、API 限流的错误态 MVP 需要但设计稿未覆盖 — 建议用系统 alert，文案风格见下。

## Content / Copy 规则

- 中文为主、简洁、不卖萌；不用 emoji；不用感叹号轰炸。引导语示例：`请开始说话吧`、`为保证同传效果，请靠近麦克风说话`。
- 语言标签全大写英文（`ENGLISH`）或 `中文 · 普通话` 格式。

## Design Tokens

**颜色（核心）**
| Token | 值 | 用途 |
|---|---|---|
| ink-950 / 900 / 800 | `#07070C` `#0C0C14` `#14141F` | 暗色舞台 / 卡片 |
| ink-400 / 300 / 100 | `#6B6B85` `#9494AE` `#E9E9F2` | 暗色下的次要/主要文字 |
| violet-600 / 500 / 400 | `#5B3DF5` `#7050FF` `#8F76FF` | 我方面板 / 主操作 / 链接色 |
| aqua-500 | `#2BD9C8` | 录音中（live）一切元素 |
| red-500 | `#FF5C5C` | 破坏性操作 |
| 浅色 surface | `#F7F7FB` 底 / `#FFFFFF` 卡 | 设置等浏览面 |

**字体**：iOS 直接用 **SF Pro（系统字体）+ PingFang SC**——设计稿里的 Inter 是 Web 替身，系统字体即正确实现。字号（pt）：caption2 11 · caption 13 · subhead 15 · body 17 · title3 20 · title2 22 · title1 28 · largeTitle 34；**字幕专用**：partial 22 · final 30 · history 17。行高 1.2/1.4/1.5。

**间距**：4pt 基数（4/8/12/16/20/24/32/40/48/64）；屏幕水平 inset 20pt；最小点击区 44pt；主操作高 56pt。

**圆角**：控件 12 · 卡片 16 · sheet 28 · 胶囊 999。

**阴影/辉光**：见 `design/tokens/effects.css`（辉光只用于活跃语音元素——麦克风、水面，别处不用）。

## Assets

- 图标：设计稿用 Lucide 线性图标（2pt 描边）。iOS 实现用 **SF Symbols** 等价替换：`mic`、`gearshape`、`arrow.left.arrow.right`、`chevron.left/right`、`checkmark`。无自定义图标资产。
- 无图片资产。水面波形是程序绘制，不是素材。

## Files

```
design/
  mvp.html                  ← 交互式预览（两台手机并排）
  live-screen.jsx           ← 同传屏设计参考
  settings-screen.jsx       ← 设置屏设计参考
  components/               ← water-surface · mic-button · transcript-line · live-badge · switch · icon-button（参考实现）
  tokens/                   ← colors / typography / spacing / effects / motion（token 的唯一事实来源）
  styles.css
```

> 预览方式：在 `design/` 目录 `python3 -m http.server`，浏览器开 `mvp.html`。（fonts 未打包——预览会回退系统字体，不影响规格。）

## 给 Claude Code 的建议提示词

> 阅读 design_handoff_mvp/README.md，按其中规格用 SwiftUI 制定 VRecorder MVP 的开发计划：项目结构、AVAudioEngine 录音 + 流式 STT/翻译（Claude/OpenAI 可切换的 provider 协议）、同传屏与设置屏的视图实现、WaterSurface 的 TimelineView+Canvas 实现。先出计划再写代码。
