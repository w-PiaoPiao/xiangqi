# 开发规范

## 1. 代码规范

### 1.1 JavaScript
- 使用 ES6+ 语法（const, let, arrow functions, template literals）
- 使用严格模式 `'use strict'`
- 禁止使用全局变量（封装在模块/对象中）
- 函数命名采用 camelCase
- 常量命名采用 UPPER_SNAKE_CASE
- 类/构造函数名采用 PascalCase

### 1.2 CSS
- 使用 CSS3 特性
- class 命名采用 kebab-case
- 颜色值使用十六进制或 `rgba()`
- 避免使用 `!important`

### 1.3 HTML
- HTML5 doctype
- 语义化标签
- 内嵌 CSS 在 `<head>` 中
- 内嵌 JS 在 `</body>` 前

## 2. 注释规范
- 每个函数/方法添加 JSDoc 风格注释
- 复杂逻辑添加行内注释
- 使用中文注释

## 3. 数据规范
- 棋盘使用 `[row][col]` 索引
- 颜色统一使用 `'red'` / `'black'`
- 棋子类型使用英文：`general`, `advisor`, `elephant`, `horse`, `chariot`, `cannon`, `soldier`

## 4. 开发流程
1. 每个功能先更新 `docs/dev-steps.md` 标记进度
2. 编码后在 `devlog/` 中记录完成内容
3. 逐阶段推进，通过一个阶段的验收后再进入下一阶段
4. 每次改动保持文件整洁，无冗余代码

## 5. 验收集成标准
- 无控制台错误
- 棋盘渲染完整无错
- 所有棋子走法符合中国象棋规则
- 游戏流程完整（从开局到分出胜负）
