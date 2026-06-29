# 中国象棋 (Xiangqi)

轻量化本地中国象棋应用，支持三个平台：

| 平台 | 路径 | 技术 |
|------|------|------|
| 🌐 Web | `index.html` | 单 HTML 文件，零依赖 |
| 📱 Android | `android/` | Kotlin + Jetpack Compose |
 | 🧩 HarmonyOS Next | `xiangqi-hmos/` | ArkTS + ArkUI |

## 功能

- **标准棋盘**：9×10 格线，楚河汉界，九宫斜线
- **完整走法**：7 种棋子规则（蹩马腿、塞象眼、炮翻山、将帅对面）
- **交互反馈**：选中高亮（金色外圈）、合法走法提示（绿色圆点）、将军警告
- **游戏管理**：回合切换、吃子、将杀/困毙检测、悔棋
- **吃子盒子**：被吃棋子分类展示 + 数量角标
- **走棋历史**：代数式记录，红黑标注
- **多端适配**：响应式布局（手机竖排 / PC 横排）、触屏支持、Retina 显示

## 快速开始

### Web 版

直接双击 `index.html` 在浏览器中打开：

```
open index.html
```

或通过本地服务器运行：

```
python3 -m http.server 8080
# 访问 http://localhost:8080
```

### Android 版

用 Android Studio 打开 `android/` 目录，构建 APK：

```
./gradlew assembleDebug
# 输出: android/app/build/outputs/apk/debug/app-debug.apk
```

### HarmonyOS Next 版

用 DevEco Studio 打开 `xiangqi-hmos/` 目录，或在终端构建：

```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
cd xiangqi-hmos && ./hvigorw assembleHap --no-daemon
# 输出: xiangqi-hmos/entry/build/default/outputs/default/entry-default-unsigned.hap
```

> 注：HAP 未签名时仅能用于模拟器或调试；真机安装需在 DevEco Studio 中配置 signingConfigs。

## 游戏规则

- 红方先行，双方轮流操作
- 点击己方棋子选中（金色高亮），再点击合法目标走棋
- 点击空位或敌方棋子取消选中
- 棋子走法范围以绿色圆点标示
- 将军时状态栏变红提示

## 技术栈

### Web
| 技术 | 用途 |
|------|------|
| HTML5 | 页面结构 |
| CSS3 | 布局、样式、响应式 |
| Canvas 2D | 棋盘和棋子渲染 |
| JavaScript (ES6+) | 游戏逻辑和交互 |
| 零外部依赖，无框架，无 CDN |

### Android
| 技术 | 用途 |
|------|------|
| Kotlin | 语言 |
| Jetpack Compose | UI 框架 |
| Canvas API | 棋盘和棋子渲染 |

### HarmonyOS Next
| 技术 | 用途 |
|------|------|
| ArkTS | 语言（TypeScript 子集） |
| ArkUI | UI 框架（声明式组件） |
| Canvas API | 棋盘和棋子渲染 |

## 项目结构

```
xiangqi/
├── index.html              # Web 版入口
├── android/                # Android 项目
│   └── app/src/main/java/com/xiangqi/
│       ├── GameEngine.kt   # 游戏逻辑引擎
│       └── MainActivity.kt # UI + Canvas 渲染
├── xiangqi-hmos/           # HarmonyOS Next 项目
│   └── entry/src/main/ets/
│       ├── engine/GameEngine.ets   # 游戏逻辑引擎
│       ├── ui/BoardCanvas.ets      # Canvas 棋盘组件
│       ├── ui/GameView.ets         # 主界面布局
│       ├── ui/CapturedBox.ets      # 吃子展示组件
│       └── model/Piece.ets         # 数据模型
├── docs/                   # 开发文档
│   ├── requirements.md
│   ├── architecture.md
│   ├── ui-design.md
│   ├── standards.md
│   └── dev-steps.md
├── devlog/                 # 开发日志
│   └── YYYY-MM-DD.md
├── CLAUDE.md               # AI 工作指引
└── README.md
```

## 开发

详见 [docs/dev-steps.md](docs/dev-steps.md) 了解当前开发阶段和计划。

## License

MIT
