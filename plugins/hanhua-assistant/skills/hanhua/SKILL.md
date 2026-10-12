---
name: hanhua
description: Safely localize software, websites, and games into Simplified Chinese (zh-CN), including string inventory, translation, placeholders, locale resources, fonts, and QA. Use when the user mentions 汉化, 中文化, 简体中文, localization, i18n, l10n, locale files, or translation resources.
---

# 汉化助手

把用户可见文本可靠地本地化为简体中文，同时保护程序逻辑、格式标记和既有产品语气。默认目标语言是 `zh-CN`，除非用户明确指定其他中文变体。

## 先盘点，再修改

1. 识别项目类型、框架、语言资源格式和已有目标语言文件。
2. 搜索 `locale`、`i18n`、`l10n`、`lang`、`translation`、`messages`、`strings`、资源文件及界面组件。
3. 区分用户可见文本与以下内容：
   - 代码标识符、对象键、数据库字段、API 名称、日志键；
   - 文件路径、URL、命令、正则、协议字段、MIME 类型；
   - CSS 类名、测试快照、示例代码、注释；
   - 占位符、转义序列、HTML/Markdown 标记和格式说明。
4. 在做大量修改前，先给出范围、资源文件、风险点和验证方式。
5. 如果项目已有翻译平台或术语表，优先沿用；冲突时说明并提出统一方案。

## 翻译原则

- 使用自然、简洁、统一的简体中文，优先采用中国大陆常见软件用语。
- 保持原文功能、语气、标点和含义；不要擅自增加解释、推广语或情绪。
- 按钮、菜单和短标签尽量简短，避免在窄空间中造成截断。
- 中文通常不使用复数变化，不要机械添加“们”；英文冠词和介词通常省略。
- 句子中的中文标点使用全角；代码、参数、路径和英文品牌名保持原样。
- 混排时遵循项目既有风格。项目没有规则时，中英文之间不强行添加空格。
- 保留品牌名、专有名词和缩写；首次出现且用户可能不认识时，可写成“中文名（English Name）”。
- 不在翻译文本中硬编码快捷键、平台名称或 UI 行为；沿用源文本和项目惯例。
- 不确定的专业术语要记录在术语表中，不要在同一产品里使用多个译法。

## 必须保护的内容

逐字保留并可验证的内容包括：

- `{name}`、`{{name}}`、`${name}`、`%s`、`%1$s`、`:name` 等占位符；
- `%d`、`%.2f` 等格式说明符；
- `\n`、`\t`、`\\`、`&amp;`、`&lt;` 等转义或实体；
- HTML/XML/Vue/React/Markdown 等标记结构；
- ICU MessageFormat、复数、选择和嵌套语法；
- 富文本标签、链接、变量名和命令参数。

翻译后必须逐项比较占位符和转义序列；数量或名称发生变化时，视为错误并修正。

## 资源文件实现

1. 优先修改现有目标语言文件，不复制代码逻辑。
2. 保留资源文件结构、键名、排序和编码要求。
3. JSON 使用 UTF-8；若项目原本无 BOM，保持无 BOM。
4. 只有目标语言确实需要时才增加复数、性别等键。
5. 不把语言判断写成散落在组件中的条件分支；继续使用项目现有 i18n 机制。
6. 字体和 CSS 只在确有中日韩字形缺失时调整，并优先增加字体回退，而不是替换整套字体。

## 本地审计

对成对 JSON 资源执行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/locale-audit.ps1 `
  -Reference C:\path\to\en.json `
  -Target C:\path\to\zh-CN.json `
  -OutputPath C:\path\to\locale-audit.json
```

该脚本检查：

- 参考资源有但目标资源缺失的键；
- 目标资源多出的键；
- 空白译文；
- 与原文完全相同的疑似漏译；
- `{name}`、`{{name}}`、`${name}`、`%s`、`%1$s` 等占位符错配；
- `\n`、`\t`、`\r` 等转义序列数量变化。

脚本只审计 JSON。其他格式要使用对应解析器或项目测试，不能仅靠正则批量替换。

## 验证与交付

- 运行项目的 lint、测试和构建命令。
- 实际打开关键页面，检查截断、换行、字体回退、键盘导航和无障碍文本。
- 搜索目标语言目录中仍与英文完全相同的用户可见字符串。
- 报告改动文件、翻译范围、术语决定、验证结果和任何未解决风险。
- 不声称已完成无法运行的 GUI、打包、OCR 或二进制提权流程；明确列出需要项目所有者执行的步骤。

## 术语与风格

按需读取：

- `references/style-guide.md`：简体中文 UI 风格规则；
- `references/glossary-seed.md`：常用软件界面术语种子表。