import { Piece, PieceType, PieceColor, Pos, Move, GameStatus } from '../model/Piece'
import { GameEngine } from '../engine/GameEngine'
import { BoardCanvas } from './BoardCanvas'
import { CapturedBox } from './CapturedBox'

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

@Component
export struct GameView {
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
  @State redrawTrigger: number = 0

  aboutToAppear(): void {
    this.engine.initBoard()
    this.syncBoard()
  }

  syncBoard(): void {
    this.board = this.engine.board.map(row => [...row])
    this.turn = this.engine.turn
    this.inCheck = this.engine.inCheck
    this.status = this.engine.status
    this.history = [...this.engine.history]
    this.capturedByRed = this.engine.history
      .filter(m => m.piece.color === PieceColor.RED && m.captured !== null)
      .map(m => m.captured!)
    this.capturedByBlack = this.engine.history
      .filter(m => m.piece.color === PieceColor.BLACK && m.captured !== null)
      .map(m => m.captured!)
    this.redrawTrigger++
  }

  onCellClick(pos: Pos): void {
    if (this.status !== GameStatus.PLAYING) return
    const piece = this.board[pos.row][pos.col]

    if (!this.selectedPos) {
      if (piece && piece.color === this.turn) {
        this.selectedPos = pos
        this.validMoves = this.engine.getValidMoves(pos)
      }
      return
    }

    const sel = this.selectedPos

    if (pos.row === sel.row && pos.col === sel.col) {
      this.selectedPos = null
      this.validMoves = []
      return
    }

    if (piece && piece.color === this.turn) {
      this.selectedPos = pos
      this.validMoves = this.engine.getValidMoves(pos)
      return
    }

    if (this.validMoves.some(m => m.row === pos.row && m.col === pos.col)) {
      this.engine.executeMove(sel, pos)
      this.selectedPos = null
      this.validMoves = []
      this.syncBoard()
      return
    }

    this.selectedPos = null
    this.validMoves = []
  }

  onReset(): void {
    this.engine.initBoard()
    this.selectedPos = null
    this.validMoves = []
    this.syncBoard()
  }

  onUndo(): void {
    this.engine.undoMove()
    this.selectedPos = null
    this.validMoves = []
    this.syncBoard()
  }

  getStatusText(): string {
    if (this.status === GameStatus.RED_WINS) return '红方胜'
    if (this.status === GameStatus.BLACK_WINS) return '黑方胜'
    return this.turn === PieceColor.RED ? '红方走棋' : '黑方走棋'
  }

  getStatusColor(): string {
    if (this.status !== GameStatus.PLAYING) return '#27AE60'
    if (this.inCheck) return '#C0392B'
    return this.turn === PieceColor.RED ? '#C0392B' : '#2C3E50'
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          this.titleArea()
          this.boardArea()
          this.statusBar()
          this.controlBar()
          this.capturedArea()
          this.moveHistory()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0E8')
  }

  @Builder
  titleArea() {
    Column({ space: 4 }) {
      Text('中国象棋')
        .fontSize(24)
        .fontWeight(700)
        .fontColor('#4A3728')
        .letterSpacing(6)
      Text('本地双人对弈')
        .fontSize(12)
        .fontColor('#8a7a6a')
    }
    .width('100%')
    .padding({ top: 8, bottom: 4 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  boardArea() {
    BoardCanvas({
      board: this.board,
      selectedPos: this.selectedPos,
      validMoves: this.validMoves,
      redrawTrigger: this.redrawTrigger,
      onCellClick: (pos: Pos) => { this.onCellClick(pos) }
    })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 4 })
    .borderRadius(8)
  }

  @Builder
  statusBar() {
    Row() {
      Row({ space: 8 }) {
        Text(this.getStatusText())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getStatusColor())

        if (this.inCheck && this.status === GameStatus.PLAYING) {
          Text('将军！')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fff')
            .backgroundColor('#C0392B')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(4)
        }
      }

      Text(this.turn === PieceColor.RED ? '红' : '黑')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#fff')
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.getStatusColor())
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FAF7F0')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
  }

  @Builder
  controlBar() {
    Row({ space: 12 }) {
      Button('重新开始', { type: ButtonType.Capsule })
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#4A3728')
        .backgroundColor('#E8DCC8')
        .layoutWeight(1)
        .height(40)
        .onClick(() => { this.onReset() })

      Button('悔棋', { type: ButtonType.Capsule })
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#fff')
        .backgroundColor('#C0392B')
        .layoutWeight(1)
        .height(40)
        .onClick(() => { this.onUndo() })
    }
    .width('100%')
  }

  @Builder
  capturedArea() {
    Row({ space: 12 }) {
      CapturedBox({ label: '红方吃子', pieces: this.capturedByRed })
        .layoutWeight(1)
      CapturedBox({ label: '黑方吃子', pieces: this.capturedByBlack })
        .layoutWeight(1)
    }
    .width('100%')
  }

  buildMoveLine(move: Move, index: number): string {
    const prefix = index % 2 === 0 ? `${index / 2 + 1}. ` : ''
    return `${prefix}${formatMove(move)}`
  }

  getMoveColor(move: Move): string {
    return move.piece.color === PieceColor.RED ? '#C0392B' : '#2C3E50'
  }

  @Builder
  moveHistory() {
    Column({ space: 8 }) {
      Text('走棋记录')
        .fontSize(12)
        .fontColor('#8a7a6a')
        .width('100%')

      Scroll() {
        Column({ space: 4 }) {
          ForEach(this.history, (move: Move, index: number) => {
            Row() {
              Text(this.buildMoveLine(move, index))
                .fontSize(13)
                .fontColor(this.getMoveColor(move))
                .fontFamily('Courier New, Courier, monospace')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
          }, (move: Move, index: number) => `${index}-${move.from.row},${move.from.col}-${move.to.row},${move.to.col}`)
        }
      }
      .width('100%')
      .height(120)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAF7F0')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
  }
}
