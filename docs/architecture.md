# 技术架构设计

## 1. 技术选型
| 层级 | 技术 | 理由 |
|------|------|------|
| 渲染 | Canvas 2D API | 适合网格线绘制，性能好 |
| 逻辑 | 原生 JavaScript (ES6+) | 零依赖，轻量 |
| 样式 | CSS3 | 页面布局与响应式 |
| 交互 | DOM + Canvas 点击事件 | 点击事件映射到棋盘坐标 |

## 2. 文件结构
```
xiangqi/
├── index.html      # 唯一入口文件（内嵌 CSS 和 JS）
├── CLAUDE.md       # AI 工作指引
├── docs/           # 开发文档
│   ├── requirements.md
│   ├── architecture.md
│   ├── ui-design.md
│   ├── standards.md
│   └── dev-steps.md
└── devlog/         # 开发日志
    ├── README.md
    └── YYYY-MM-DD.md
```

## 3. 数据模型

### 3.1 棋盘状态 (board)
```
10行 × 9列 二维数组
board[row][col] = {
  type: 'general' | 'advisor' | 'elephant' | 'horse' | 'chariot' | 'cannon' | 'soldier',
  color: 'red' | 'black'
} | null
```

### 3.2 游戏状态 (gameState)
```javascript
{
  board:        Array[10][9],  // 棋盘
  turn:         'red' | 'black',  // 当前走棋方
  selected:     { row, col } | null,  // 选中的棋子
  validMoves:   [{ row, col }],  // 合法走法
  history:      [{ piece, from, to, captured }],  // 走棋历史
  status:       'playing' | 'red_wins' | 'black_wins' | 'draw',
  inCheck:      false,  // 当前是否被将军
}
```

## 4. 模块划分

### 4.1 渲染模块 (Renderer)
- `drawBoard()`: 绘制棋盘网格、九宫斜线、河界
- `drawPieces()`: 绘制所有棋子
- `drawSelection()`: 绘制选中高亮
- `drawValidMoves()`: 绘制合法走法提示
- `clearCanvas()`: 清空画布

### 4.2 逻辑模块 (GameEngine)
- `initBoard()`: 初始化棋子布局
- `getValidMoves(row, col)`: 获取某棋子的合法走法
- `movePiece(from, to)`: 执行走棋
- `isInCheck(color)`: 检测某方是否被将军
- `isCheckmate(color)`: 检测某方是否被将杀
- `isFlyingGeneral()`: 检测将帅对面
- `undo()`: 悔棋
- `reset()`: 重置游戏

### 4.3 走法判定子模块
- `getGeneralMoves()`
- `getAdvisorMoves()`
- `getElephantMoves()` + 塞象眼检测
- `getHorseMoves()` + 蹩马腿检测
- `getChariotMoves()`
- `getCannonMoves()`
- `getSoldierMoves()`

### 4.4 交互模块 (EventHandler)
- `handleCanvasClick(event)`: 画布点击事件处理
- `selectPiece(row, col)`: 选中棋子
- `executeMove(row, col)`: 执行走棋
- `updateUI()`: 更新状态显示和历史

## 5. 渲染流程
```
游戏状态变更
  → clearCanvas()
  → drawBoard()
  → drawPieces()
  → drawSelection() (如果有选中)
  → drawValidMoves() (如果有选中)
  → updateUI()
```

## 6. 事件处理流程
```
用户点击画布
  → 计算点击位置对应的棋盘点 (row, col)
  → 如果未选中棋子：
      → 如果该点有己方棋子 → 选中
      → 否则 → 忽略
  → 如果已选中棋子：
      → 如果点击己方另一棋子 → 切换选中
      → 如果点击合法目标 → 执行走棋
      → 如果点击非法目标 → 忽略/取消选中
```

## 7. 坐标系统
- 行 (row): 0-9，从上到下（0 = 黑方底线，9 = 红方底线）
- 列 (col): 0-8，从左到右
- 黑方在棋盘上方 (row 0-4)，红方在棋盘下方 (row 5-9)
