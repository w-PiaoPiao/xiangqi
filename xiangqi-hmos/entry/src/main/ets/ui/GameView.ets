import { Piece, PieceType, PieceColor, Pos, Move, GameStatus } from '../model/Piece'
import { GameEngine } from '../engine/GameEngine'
import { BoardCanvas } from './BoardCanvas'

const PIECE_NAMES = {
  red: { general: '帅', advisor: '仕', elephant: '相', horse: '马', chariot: '车', cannon: '炮', soldier: '兵' },
  black: { general: '将', advisor: '士', elephant: '象', horse: '马', chariot: '车', cannon: '砲', soldier: '卒' }
}

function formatMove(move: Move): string {
  const name = move.piece.displayName
  const c1 = 9 - move.from.col
  const c2 = 9 - move.to.col
  const dr = move.to.row - move.from.row
  const isRed = move.piece.color === PieceColor.RED
  const fwd = isRed ? dr < 0 : dr > 0
  const dir = dr === 0 ? '平' : fwd ? '进' : '退'
  return `${name}${c1}${dir}${c2}`
}

@Entry
@Component
struct GameView {
  private engine: GameEngine = new GameEngine()

  @State board: (Piece | null)[][] = this.engine.board
  @State turn: PieceColor = PieceColor.RED
  @State selectedPos: Pos | null = null
  @State validMoves: Pos[] = []
  @State inCheck: boolean = false
  @State status: GameStatus = GameStatus.PLAYING
  @State history: Move[] = []
  @State capturedByRed: Piece[] = []
  @State capturedByBlack: Piece[] = []

  @State breakpoint: string = 'sm'
  @State debugText: string = '点击棋子开始'

  aboutToAppear(): void {
    this.engine.initBoard()
    this.syncBoard()
  }

  syncBoard(): void {
    this.board = this.engine.board
    this.turn = this.engine.turn
    this.inCheck = this.engine.inCheck
    this.status = this.engine.status
    this.history = this.engine.history
    this.capturedByRed = this.engine.capturedByRed
    this.capturedByBlack = this.engine.capturedByBlack
  }

  onCellClick(pos: Pos): void {
    if (this.status !== GameStatus.PLAYING) return

    this.debugText = `点击 (${pos.row},${pos.col})`
    const piece = this.board[pos.row][pos.col]

    if (!this.selectedPos) {
      if (piece && piece.color === this.turn) {
        this.debugText = `选中 (${pos.row},${pos.col}) ${piece.displayName}`
        this.selectedPos = pos
        this.validMoves = this.engine.getValidMoves(pos)
      }
      return
    }

    const sel = this.selectedPos

    if (pos.row === sel.row && pos.col === sel.col) {
      this.debugText = '取消选中'
      this.selectedPos = null
      this.validMoves = []
      return
    }

    if (piece && piece.color === this.turn) {
      this.debugText = `切换选中 (${pos.row},${pos.col}) ${piece.displayName}`
      this.selectedPos = pos
      this.validMoves = this.engine.getValidMoves(pos)
      return
    }

    if (this.validMoves.some(m => m.row === pos.row && m.col === pos.col)) {
      this.debugText = `走棋 (${sel.row},${sel.col})→(${pos.row},${pos.col})`
      this.engine.executeMove(sel, pos)
      this.selectedPos = null
      this.validMoves = []
      this.syncBoard()
      return
    }

    this.debugText = `无效点击 (${pos.row},${pos.col})`
    this.selectedPos = null
    this.validMoves = []
  }

  onReset(): void {
    this.engine.initBoard()
    this.selectedPos = null
    this.validMoves = []
    this.debugText = '新对局'
    this.syncBoard()
  }

  onUndo(): void {
    this.engine.undoMove()
    this.selectedPos = null
    this.validMoves = []
    this.syncBoard()
  }

  // ---------- layout ----------

  build() {
    Column() {
      if (this.breakpoint === 'lg') {
        this.desktopLayout()
      } else if (this.breakpoint === 'md') {
        this.tabletLayout()
      } else {
        this.phoneLayout()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0E8')
  }

  // ---- Phone layout ----
  @Builder
  phoneLayout() {
    Scroll() {
      Column() {
        this.titleBar()
        BoardCanvas({
          board: this.board,
          selectedPos: this.selectedPos,
          validMoves: this.validMoves,
          onCellClick: (pos: Pos) => this.onCellClick(pos)
        })

        Row() {
          this.capturedBox('红方吃子', this.capturedByRed)
          this.capturedBox('黑方吃子', this.capturedByBlack)
        }
        .width('100%')
        .padding({ top: 8 })

        this.statusBar()
        this.controlButtons()
        this.moveHistory()
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
  }

  // ---- Tablet layout ----
  @Builder
  tabletLayout() {
    Row() {
      BoardCanvas({
        board: this.board,
        selectedPos: this.selectedPos,
        validMoves: this.validMoves,
        onCellClick: (pos: Pos) => this.onCellClick(pos)
      })
      .width('60%')

      Column() {
        this.titleBar()
        Row() {
          this.capturedBox('红方吃子', this.capturedByRed)
          this.capturedBox('黑方吃子', this.capturedByBlack)
        }
        .width('100%')
        this.statusBar()
        this.controlButtons()
        this.moveHistory()
      }
      .width('40%')
      .padding({ left: 12 })
    }
    .width('100%')
    .height('100%')
    .padding(12)
  }

  // ---- Desktop layout ----
  @Builder
  desktopLayout() {
    Row() {
      BoardCanvas({
        board: this.board,
        selectedPos: this.selectedPos,
        validMoves: this.validMoves,
        onCellClick: (pos: Pos) => this.onCellClick(pos)
      })
      .width('55%')

      Column() {
        this.titleBar()
        Row() {
          this.capturedBox('红方吃子', this.capturedByRed)
          this.capturedBox('黑方吃子', this.capturedByBlack)
        }
        .width('100%')
        this.statusBar()
        this.controlButtons()
        this.moveHistory()
      }
      .width('45%')
      .padding({ left: 16 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  // ---- Shared components ----
  @Builder
  titleBar() {
    Text('中 国 象 棋')
      .fontSize(20)
      .fontWeight(600)
      .fontColor('#4A3728')
      .letterSpacing(4)
      .padding({ bottom: 4 })

    Text(this.debugText)
      .fontSize(12)
      .fontColor('#666')
      .width('100%')
      .height(20)
      .textAlign(TextAlign.Center)
  }

  @Builder
  capturedBox(label: string, pieces: Piece[]) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor('#8a7a6a')
      Row() {
        ForEach(pieces, (piece: Piece) => {
          Text(piece.displayName)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fff')
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor(piece.color === PieceColor.RED ? '#C0392B' : '#2C3E50')
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')
    }
    .padding(6)
    .backgroundColor('#FAF7F0')
    .borderRadius(8)
  }

  @Builder
  statusBar() {
    let bg = this.status !== GameStatus.PLAYING ? '#E8F5E9'
      : this.inCheck ? '#FDE8E8' : '#FAF7F0'
    let text = this.status === GameStatus.RED_WINS ? '🏆 红方胜！'
      : this.status === GameStatus.BLACK_WINS ? '🏆 黑方胜！'
      : this.turn === PieceColor.RED ? '红方走棋' : '黑方走棋'

    Row() {
      Text(text)
        .fontSize(14)
      if (this.inCheck && this.status === GameStatus.PLAYING) {
        Text('⚠️ 将军！')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C0392B')
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(bg)
    .borderRadius(8)
    .margin({ top: 8 })
  }

  @Builder
  controlButtons() {
    Row() {
      Button('重新开始')
        .onClick(() => this.onReset())
      Button('悔棋')
        .onClick(() => this.onUndo())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 8 })
  }

  @Builder
  moveHistory() {
    Column() {
      Text('走棋记录')
        .fontSize(12)
        .fontColor('#8a7a6a')
      Scroll() {
        Column() {
          ForEach(this.history, (move: Move, index: number) => {
            let prefix = index % 2 === 0 ? `${Math.floor(index / 2) + 1}. ` : ''
            let color = move.piece.color === PieceColor.RED ? '#C0392B' : '#2C3E50'
            let suffix = index % 2 === 0 ? '  ' : '\n'
            Text(`${prefix}${formatMove(move)}${suffix}`)
              .fontSize(13)
              .fontColor(color)
              .fontFamily('Courier New, Courier, monospace')
          })
        }
      }
      .width('100%')
      .height(120)
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#FAF7F0')
    .borderRadius(8)
    .margin({ top: 8 })
  }
}
