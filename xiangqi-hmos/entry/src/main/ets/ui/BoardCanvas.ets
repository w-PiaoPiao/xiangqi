import { Piece, PieceColor, Pos } from '../model/Piece'

const COLS = 9
const ROWS = 10
const MARGIN_RATIO = 0.05

class BoardLayout {
  left: number = 0
  top: number = 0
  cellW: number = 0
  cellH: number = 0
}

@Component
export struct BoardCanvas {
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D()
  private w: number = 0
  private h: number = 0

  @Prop board: (Piece | null)[][] = []
  @Prop selectedPos: Pos | null = null
  @Prop validMoves: Pos[] = []
  @Prop @Watch('onRedraw') redrawTrigger: number = 0
  onCellClick: ((pos: Pos) => void) | null = null

  onRedraw(propName: string): void {
    if (this.w > 0 && this.h > 0) {
      this.drawAll()
    }
  }

  drawAll(): void {
    const ctx = this.context
    const w = this.w
    const h = this.h
    ctx.clearRect(0, 0, w, h)

    const l = this.calcLayout(w, h)
    const right = l.left + l.cellW * (COLS - 1)
    const bottom = l.top + l.cellH * (ROWS - 1)

    ctx.fillStyle = '#DEB887'
    ctx.fillRect(0, 0, w, h)

    ctx.strokeStyle = '#4A3728'
    ctx.lineWidth = 2
    ctx.strokeRect(l.left, l.top, right - l.left, bottom - l.top)
    ctx.lineWidth = 1

    for (let row = 0; row < ROWS; row++) {
      const y = l.top + row * l.cellH
      ctx.beginPath()
      ctx.moveTo(l.left, y)
      ctx.lineTo(right, y)
      ctx.stroke()
    }

    for (let col = 0; col < COLS; col++) {
      const x = l.left + col * l.cellW
      if (col === 0 || col === COLS - 1) {
        ctx.beginPath(); ctx.moveTo(x, l.top); ctx.lineTo(x, bottom); ctx.stroke()
      } else {
        ctx.beginPath(); ctx.moveTo(x, l.top); ctx.lineTo(x, l.top + 4 * l.cellH); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(x, l.top + 5 * l.cellH); ctx.lineTo(x, bottom); ctx.stroke()
      }
    }

    ctx.beginPath()
    ctx.moveTo(l.left + 3 * l.cellW, l.top); ctx.lineTo(l.left + 5 * l.cellW, l.top + 2 * l.cellH)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(l.left + 5 * l.cellW, l.top); ctx.lineTo(l.left + 3 * l.cellW, l.top + 2 * l.cellH)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(l.left + 3 * l.cellW, l.top + 7 * l.cellH); ctx.lineTo(l.left + 5 * l.cellW, l.top + 9 * l.cellH)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(l.left + 5 * l.cellW, l.top + 7 * l.cellH); ctx.lineTo(l.left + 3 * l.cellW, l.top + 9 * l.cellH)
    ctx.stroke()

    const radius = Math.min(l.cellW, l.cellH) * 0.42
    for (let r = 0; r < ROWS; r++) for (let c = 0; c < COLS; c++) {
      const piece = this.board[r][c]
      if (!piece) continue
      const cx = l.left + c * l.cellW, cy = l.top + r * l.cellH
      const isRed = piece.color === PieceColor.RED

      ctx.save()
      ctx.beginPath(); ctx.arc(cx + 1.5, cy + 2, radius, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(0,0,0,0.18)'; ctx.fill()
      ctx.restore()

      const grad = ctx.createRadialGradient(cx - radius * 0.3, cy - radius * 0.3, radius * 0.1, cx, cy, radius)
      grad.addColorStop(0, isRed ? '#E74C3C' : '#5D6D7E')
      grad.addColorStop(1, isRed ? '#A93226' : '#1a252f')
      ctx.beginPath(); ctx.arc(cx, cy, radius, 0, Math.PI * 2)
      ctx.fillStyle = grad; ctx.fill()
      ctx.strokeStyle = isRed ? '#8B1A1A' : '#111820'; ctx.lineWidth = 1.5; ctx.stroke()

      ctx.beginPath(); ctx.arc(cx, cy, radius * 0.78, 0, Math.PI * 2)
      ctx.strokeStyle = isRed ? 'rgba(255,255,255,0.35)' : 'rgba(255,255,255,0.25)'
      ctx.lineWidth = 1; ctx.stroke()

      ctx.fillStyle = '#fff'
      ctx.font = `bold ${Math.max(24, Math.floor(radius * 2.2))}px HarmonyOS Sans, sans-serif`
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillText(piece.displayName, cx, cy + 1)
    }

    const dotR = Math.max(6, Math.min(l.cellW, l.cellH) * 0.18)
    for (const m of this.validMoves) {
      const mx = l.left + m.col * l.cellW
      const my = l.top + m.row * l.cellH
      ctx.beginPath()
      ctx.arc(mx, my, dotR, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(39, 174, 96, 0.85)'
      ctx.fill()
      ctx.beginPath()
      ctx.arc(mx, my, dotR + 2, 0, Math.PI * 2)
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.7)'
      ctx.lineWidth = 1.5
      ctx.stroke()
    }

    if (this.selectedPos) {
      const sx = l.left + this.selectedPos.col * l.cellW
      const sy = l.top + this.selectedPos.row * l.cellH
      const sr = Math.min(l.cellW, l.cellH) * 0.42 + 4
      ctx.beginPath(); ctx.arc(sx, sy, sr, 0, Math.PI * 2)
      ctx.strokeStyle = '#F1C40F'; ctx.lineWidth = 3; ctx.stroke()
    }
  }

  calcLayout(w: number, h: number): BoardLayout {
    const l = new BoardLayout()
    l.left = w * MARGIN_RATIO
    l.top = h * MARGIN_RATIO
    l.cellW = (w - 2 * l.left) / (COLS - 1)
    l.cellH = (h - 2 * l.top) / (ROWS - 1)
    return l
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.w = this.context.width
          this.h = this.context.height
          this.drawAll()
        })
        .onAreaChange((_, newArea) => {
          this.w = newArea.width as number
          this.h = newArea.height as number
          this.drawAll()
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            const x = event.touches[0].x
            const y = event.touches[0].y
            const l = this.calcLayout(this.w, this.h)
            const col = Math.round((x - l.left) / l.cellW)
            const row = Math.round((y - l.top) / l.cellH)
            if (col >= 0 && col < COLS && row >= 0 && row < ROWS && this.onCellClick) {
              this.onCellClick(new Pos(row, col))
            }
          }
        })
    }
    .width('100%')
    .aspectRatio(COLS / ROWS)
    .backgroundColor('#DEB887')
  }
}
