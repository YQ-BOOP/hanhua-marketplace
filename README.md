# 汉化助手 · Codex 插件源

把**软件、网站和游戏**安全地汉化为简体中文。

> 它不是一个翻译器。它按「先盘点 → 再翻译 → 后验证」的流程工作：保留代码标识符、变量、标记和占位符，**不把程序改坏**。

## 为什么不能直接让 AI 翻译语言文件？

因为那样经常会把程序改坏。真实会踩的坑：

| 事故 | 后果 |
| --- | --- |
| 把 `{count}` 这类占位符也翻译了 | 程序崩溃或显示乱码 |
| 把 CSS 类名、JSON 键名当文案翻译 | 功能直接失效 |
| 同一概念在不同文件里译法不同 | 界面上「设置 / 设定 / 配置」三个词指同一个东西 |
| 漏译的条目没人发现 | 中文界面里冒出一句英文 |

汉化助手把这些当作流程的一部分来处理，而不是靠运气。

## 能做什么

| 能力 | 说明 |
| --- | --- |
| 文本盘点 | 扫描项目，区分「用户可见文本」和「不能动的代码」，先给方案再动手 |
| 简体中文翻译 | 按统一术语表和 UI 风格指南产出译文，同一概念不出现多种译法 |
| 资源文件落地 | 生成或更新 JSON / YAML / PO / CSV / 组件级 i18n 资源 |
| 语言文件审计 | 检查缺失键、空白译文、漏译、多余键、占位符与转义序列错配 |
| 交付报告 | 收尾时说明改动范围、术语决定、验证结果和未解决项 |

## 附带资料

- **术语种子表**（66 条）：常用界面术语的统一译法
- **常见误译对照**：13 组最容易翻错的说法，例如 Import / Export 不是「进口 / 出口」
- **UI 风格指南**：标点、语气、按钮文案与平台惯例
- **审计脚本**：`skills/hanhua/scripts/locale-audit.ps1`

## 安装

需要 Codex CLI 或 Codex 桌面版。

```bash
# 1. 添加插件源
codex plugin marketplace add YQ-BOOP/hanhua-marketplace

# 2. 安装插件
codex plugin add hanhua-assistant@hanhua-local
```

安装完成后，新建一个对话即可使用。

## 用法

直接说明要汉化的项目即可：

```text
使用汉化助手扫描这个项目。先找用户可见文本和语言资源，不要修改代码标识符；
给出方案后再实施简体中文汉化。
```

也可以点名具体环节：

```text
审计 zh-CN 语言资源，检查缺失键、未翻译文本和占位符错配。
```

### 运行语言文件审计

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\hanhua-assistant\skills\hanhua\scripts\locale-audit.ps1 `
  -Reference "C:\project\locales\en.json" `
  -Target    "C:\project\locales\zh-CN.json" `
  -OutputPath "C:\project\locale-audit.json"
```

加上 `-FailOnIssues` 可在发现问题时以失败状态退出，便于接入 CI。

## 仓库结构

```text
.
├── .agents/plugins/marketplace.json      插件源清单
├── CHANGELOG.md                          更新日志
├── README.md
├── LICENSE
└── plugins/hanhua-assistant/
    ├── .codex-plugin/plugin.json         插件清单（版本号在这里）
    ├── assets/                           图标
    └── skills/hanhua/
        ├── SKILL.md                      技能说明
        ├── references/
        │   ├── style-guide.md            简体中文 UI 风格指南
        │   └── glossary-seed.md          术语种子表 + 常见误译对照
        └── scripts/
            └── locale-audit.ps1          语言文件审计脚本
```

## 适用范围与限制

**适合**：使用文本资源、JSON、YAML、PO、CSV 或组件级 i18n 的项目。

**不适合**：二进制文件、打包资源、OCR 图片文字、字体子集和 DRM 相关流程 ——
这些需要项目专用工具，不能只靠替换字符串完成。

插件**不会**绕过程序保护，也不执行未授权修改。遇到编码、文件格式或打包流程未知时，
会先分析再处理。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)。

## 许可

[MIT](LICENSE)