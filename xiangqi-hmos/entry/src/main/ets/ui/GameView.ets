import { Piece, PieceType, PieceColor, Pos, Move, GameStatus } from '../model/Piece'
import { GameEngine } from '../engine/GameEngine'
import { BoardCanvas } from './BoardCanvas'

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
  @State breakpoint: string = 'sm'
  @State debugText: string = '点击棋子开始'
  @State redrawTrigger: number = 0

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
    this.redrawTrigger++
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
      this.selectedPos = null; this.validMoves = []
      return
    }

    if (piece && piece.color === this.turn) {
      this.debugText = `切换选中 (${pos.row},${pos.col}) ${piece.displayName}`
      this.selectedPos = pos; this.validMoves = this.engine.getValidMoves(pos)
      return
    }

    if (this.validMoves.some(m => m.row === pos.row && m.col === pos.col)) {
      this.debugText = `走棋 (${sel.row},${sel.col})→(${pos.row},${pos.col})`
      this.engine.executeMove(sel, pos)
      this.selectedPos = null; this.validMoves = []
      this.syncBoard()
      return
    }

    this.debugText = `无效点击 (${pos.row},${pos.col})`
    this.selectedPos = null; this.validMoves = []
  }

  onReset(): void {
    this.engine.initBoard()
    this.selectedPos = null; this.validMoves = []
    this.debugText = '新对局'
    this.syncBoard()
  }

  onUndo(): void {
    this.engine.undoMove()
    this.selectedPos = null; this.validMoves = []
    this.syncBoard()
  }

  getStatusText(): string {
    if (this.status === GameStatus.RED_WINS) return '🏆 红方胜！'
    if (this.status === GameStatus.BLACK_WINS) return '🏆 黑方胜！'
    return this.turn === PieceColor.RED ? '红方走棋' : '黑方走棋'
  }

  getStatusBg(): string {
    if (this.status !== GameStatus.PLAYING) return '#E8F5E9'
    if (this.inCheck) return '#FDE8E8'
    return '#FAF7F0'
  }

  build() {
    Column() {
      if (this.breakpoint === 'lg') {
        this.desktopLayout()
      } else {
        Scroll() {
          Column() {
            this.titleArea()
            this.boardArea()
            this.infoArea()
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0E8')
  }

  @Builder
  titleArea() {
    Text('中 国 象 棋')
      .fontSize(20).fontWeight(600).fontColor('#4A3728').letterSpacing(4)
    Text(this.debugText)
      .fontSize(12).fontColor('#666').width('100%').height(20)
      .textAlign(TextAlign.Center)
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
  }

  @Builder
  infoArea() {
    Column() {
      Row() {
        this.capturedBox('红方吃子', this.capturedByRed)
        this.capturedBox('黑方吃子', this.capturedByBlack)
      }.width('100%')

      Row() {
        Text(this.getStatusText()).fontSize(14)
        if (this.inCheck && this.status === GameStatus.PLAYING) {
          Text('⚠️ 将军！').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#C0392B')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.getStatusBg())
      .borderRadius(8)

      Row() {
        Button('重新开始').onClick(() => { this.onReset() })
        Button('悔棋').onClick(() => { this.onUndo() })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ top: 8 })

      this.moveHistory()
    }
    .width('100%')
    .padding({ top: 8 })
  }

  @Builder
  capturedBox(label: string, pieces: Piece[]) {
    Column() {
      Text(label).fontSize(11).fontColor('#8a7a6a')
      Row() {
        ForEach(pieces, (piece: Piece) => {
          Text(piece.displayName)
            .fontSize(12).fontWeight(FontWeight.Bold).fontColor('#fff')
            .width(24).height(24).borderRadius(12)
            .backgroundColor(piece.color === PieceColor.RED ? '#C0392B' : '#2C3E50')
            .textAlign(TextAlign.Center)
        }, (piece: Piece) => piece.displayName)
      }.width('100%')
    }
    .padding(6).backgroundColor('#FAF7F0').borderRadius(8).width('50%')
  }

  buildMoveLine(move: Move, index: number): string {
    const prefix = index % 2 === 0 ? `${index / 2 + 1}. ` : ''
    const text = `${prefix}${formatMove(move)}`
    return index % 2 === 0 ? `${text}  ` : `${text}\n`
  }

  getMoveColor(move: Move): string {
    return move.piece.color === PieceColor.RED ? '#C0392B' : '#2C3E50'
  }

  @Builder
  moveHistory() {
    Column() {
      Text('走棋记录').fontSize(12).fontColor('#8a7a6a')
      Scroll() {
        Column() {
          ForEach(this.history, (move: Move, index: number) => {
            Text(this.buildMoveLine(move, index))
              .fontSize(13)
              .fontColor(this.getMoveColor(move))
              .fontFamily('Courier New, Courier, monospace')
          }, (move: Move, index: number) => `${move.from.row},${move.from.col}-${move.to.row},${move.to.col}`)
        }
      }
      .width('100%').height(120)
    }
    .width('100%').padding(8).backgroundColor('#FAF7F0').borderRadius(8)
  }

  @Builder
  desktopLayout() {
    Row() {
      BoardCanvas({
        board: this.board,
        selectedPos: this.selectedPos,
        validMoves: this.validMoves,
        redrawTrigger: this.redrawTrigger,
        onCellClick: (pos: Pos) => { this.onCellClick(pos) }
      })
      .width('55%')

      Column() {
        Text('中 国 象 棋').fontSize(20).fontWeight(600).fontColor('#4A3728').letterSpacing(4)
        Text(this.debugText).fontSize(12).fontColor('#666').width('100%').height(20)
        this.infoArea()
      }
      .width('45%')
      .padding({ left: 16 })
    }
    .width('100%').height('100%').padding(16)
  }
}
