# 汉化助手 · Codex 插件源

把**软件、网站和游戏**安全地汉化为简体中文的 Codex 插件源。

> 汉化助手不是翻译器。它按「先盘点 → 再翻译 → 后验证」的流程工作：
> 保留代码标识符、变量、标记和占位符，避免把程序改坏。

## 它能做什么

| 能力 | 说明 |
| --- | --- |
| 文本盘点 | 扫描项目，找出所有用户可见文本与语言资源，先给方案再动手 |
| 简体中文翻译 | 按统一术语表和 UI 风格指南产出译文，同一概念不出现多种译法 |
| 资源文件落地 | 生成或更新 JSON / YAML / PO / CSV / 组件级 i18n 资源 |
| 语言文件审计 | 检查缺失键、空白译文、疑似漏译、多余键、占位符与转义序列错配 |

附带工具与资料：

- **UI 风格指南**：标点、语气、按钮文案、平台惯例（`references/style-guide.md`）
- **术语种子表**：统一译法，避免同一概念多种翻译（`references/glossary-seed.md`）
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

直接说明要汉化的项目即可，例如：

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
├── .agents/plugins/marketplace.json     插件源清单
└── plugins/hanhua-assistant/
    ├── .codex-plugin/plugin.json        插件清单
    ├── assets/                          图标
    └── skills/hanhua/
        ├── SKILL.md                     技能说明
        ├── references/                  风格指南、术语表
        └── scripts/                     审计脚本
```

## 适用范围与限制

**适合**：使用文本资源、JSON、YAML、PO、CSV 或组件级 i18n 的项目。

**不适合**：二进制文件、打包资源、OCR 图片文字、字体子集和 DRM 相关流程 ——
这些需要项目专用工具，不能只靠替换字符串完成。

插件**不会**绕过程序保护，也不执行未授权修改。遇到编码、文件格式或打包流程未知时，
会先分析再处理。

## 许可

[MIT](LICENSE)