import { Piece, PieceType, PieceColor, Pos, Move, GameStatus } from '../model/Piece'

const BOARD_ROWS = 10
const BOARD_COLS = 9

export class GameEngine {
  board: (Piece | null)[][] = []
  turn: PieceColor = PieceColor.RED
  inCheck: boolean = false
  status: GameStatus = GameStatus.PLAYING
  history: Move[] = []
  capturedByRed: Piece[] = []
  capturedByBlack: Piece[] = []

  constructor() {
    this.initBoard()
  }

  initBoard(): void {
    this.board = Array.from({ length: BOARD_ROWS }, () => Array(BOARD_COLS).fill(null))

    const backRank: PieceType[] = [
      PieceType.CHARIOT, PieceType.HORSE, PieceType.ELEPHANT,
      PieceType.ADVISOR, PieceType.GENERAL, PieceType.ADVISOR,
      PieceType.ELEPHANT, PieceType.HORSE, PieceType.CHARIOT
    ]

    for (let c = 0; c < BOARD_COLS; c++) {
      this.board[0][c] = new Piece(backRank[c], PieceColor.BLACK)
    }
    this.board[2][1] = new Piece(PieceType.CANNON, PieceColor.BLACK)
    this.board[2][7] = new Piece(PieceType.CANNON, PieceColor.BLACK)
    for (let c = 0; c < BOARD_COLS; c += 2) {
      this.board[3][c] = new Piece(PieceType.SOLDIER, PieceColor.BLACK)
    }

    for (let c = 0; c < BOARD_COLS; c++) {
      this.board[9][c] = new Piece(backRank[c], PieceColor.RED)
    }
    this.board[7][1] = new Piece(PieceType.CANNON, PieceColor.RED)
    this.board[7][7] = new Piece(PieceType.CANNON, PieceColor.RED)
    for (let c = 0; c < BOARD_COLS; c += 2) {
      this.board[6][c] = new Piece(PieceType.SOLDIER, PieceColor.RED)
    }

    this.turn = PieceColor.RED
    this.inCheck = false
    this.status = GameStatus.PLAYING
    this.history = []
    this.capturedByRed = []
    this.capturedByBlack = []
  }

  // ---------- helpers ----------

  private inBoard(r: number, c: number): boolean {
    return r >= 0 && r < BOARD_ROWS && c >= 0 && c < BOARD_COLS
  }

  private findKing(color: PieceColor): Pos | null {
    for (let r = 0; r < BOARD_ROWS; r++)
      for (let c = 0; c < BOARD_COLS; c++) {
        const p = this.board[r][c]
        if (p?.type === PieceType.GENERAL && p.color === color) return new Pos(r, c)
      }
    return null
  }

  private isFlyingGeneral(): boolean {
    const rk = this.findKing(PieceColor.RED)
    const bk = this.findKing(PieceColor.BLACK)
    if (!rk || !bk || rk.col !== bk.col) return false
    const minR = Math.min(rk.row, bk.row)
    const maxR = Math.max(rk.row, bk.row)
    for (let r = minR + 1; r < maxR; r++) {
      if (this.board[r][rk.col]) return false
    }
    return true
  }

  // ---------- raw moves ----------

  private getGeneralMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    const [minR, maxR] = piece.color === PieceColor.RED ? [7, 9] : [0, 2]
    const dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    for (const [dr, dc] of dirs) {
      const nr = row + dr, nc = col + dc
      if (nr < minR || nr > maxR || nc < 3 || nc > 5) continue
      const t = this.board[nr][nc]
      if (!t || t.color !== piece.color) moves.push(new Pos(nr, nc))
    }
    return moves
  }

  private getAdvisorMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    const [minR, maxR] = piece.color === PieceColor.RED ? [7, 9] : [0, 2]
    for (const [dr, dc] of [[-1, -1], [-1, 1], [1, -1], [1, 1]]) {
      const nr = row + dr, nc = col + dc
      if (nr < minR || nr > maxR || nc < 3 || nc > 5) continue
      const t = this.board[nr][nc]
      if (!t || t.color !== piece.color) moves.push(new Pos(nr, nc))
    }
    return moves
  }

  private getElephantMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    const isRed = piece.color === PieceColor.RED
    const dirs = [[-2, -2], [-2, 2], [2, -2], [2, 2]]
    const eyes = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
    for (let i = 0; i < 4; i++) {
      const nr = row + dirs[i][0], nc = col + dirs[i][1]
      const er = row + eyes[i][0], ec = col + eyes[i][1]
      if (!this.inBoard(nr, nc)) continue
      if (isRed && nr < 5) continue
      if (!isRed && nr > 4) continue
      if (this.board[er][ec]) continue
      const t = this.board[nr][nc]
      if (!t || t.color !== piece.color) moves.push(new Pos(nr, nc))
    }
    return moves
  }

  private getHorseMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    const jumps = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]]
    const legs  = [[-1,  0], [-1, 0], [ 0, -1], [ 0, 1], [0, -1], [0, 1], [ 1,  0], [ 1, 0]]
    for (let i = 0; i < 8; i++) {
      const nr = row + jumps[i][0], nc = col + jumps[i][1]
      const lr = row + legs[i][0], lc = col + legs[i][1]
      if (!this.inBoard(nr, nc)) continue
      if (this.board[lr][lc]) continue
      const t = this.board[nr][nc]
      if (!t || t.color !== piece.color) moves.push(new Pos(nr, nc))
    }
    return moves
  }

  private getChariotMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    for (const [dr, dc] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      let nr = row + dr, nc = col + dc
      while (this.inBoard(nr, nc)) {
        const t = this.board[nr][nc]
        if (!t) moves.push(new Pos(nr, nc))
        else { if (t.color !== piece.color) moves.push(new Pos(nr, nc)); break }
        nr += dr; nc += dc
      }
    }
    return moves
  }

  private getCannonMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    for (const [dr, dc] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      let nr = row + dr, nc = col + dc, jumped = false
      while (this.inBoard(nr, nc)) {
        const t = this.board[nr][nc]
        if (!jumped) {
          if (!t) moves.push(new Pos(nr, nc))
          else jumped = true
        } else {
          if (t) { if (t.color !== piece.color) moves.push(new Pos(nr, nc)); break }
        }
        nr += dr; nc += dc
      }
    }
    return moves
  }

  private getSoldierMoves(row: number, col: number, piece: Piece): Pos[] {
    const moves: Pos[] = []
    const isRed = piece.color === PieceColor.RED
    const fwd = isRed ? -1 : 1
    const crossed = isRed ? (row <= 4) : (row >= 5)
    const nr = row + fwd
    if (this.inBoard(nr, col)) {
      const t = this.board[nr][col]
      if (!t || t.color !== piece.color) moves.push(new Pos(nr, col))
    }
    if (crossed) {
      for (const dc of [-1, 1]) {
        const nc = col + dc
        if (!this.inBoard(row, nc)) continue
        const t = this.board[row][nc]
        if (!t || t.color !== piece.color) moves.push(new Pos(row, nc))
      }
    }
    return moves
  }

  private getRawMoves(pos: Pos): Pos[] {
    const p = this.board[pos.row][pos.col]
    if (!p) return []
    switch (p.type) {
      case PieceType.GENERAL:  return this.getGeneralMoves(pos.row, pos.col, p)
      case PieceType.ADVISOR:  return this.getAdvisorMoves(pos.row, pos.col, p)
      case PieceType.ELEPHANT: return this.getElephantMoves(pos.row, pos.col, p)
      case PieceType.HORSE:    return this.getHorseMoves(pos.row, pos.col, p)
      case PieceType.CHARIOT:  return this.getChariotMoves(pos.row, pos.col, p)
      case PieceType.CANNON:   return this.getCannonMoves(pos.row, pos.col, p)
      case PieceType.SOLDIER:  return this.getSoldierMoves(pos.row, pos.col, p)
    }
  }

  // ---------- check ----------

  isInCheck(color: PieceColor): boolean {
    const king = this.findKing(color)
    if (!king) return true
    const opp = color === PieceColor.RED ? PieceColor.BLACK : PieceColor.RED
    for (let r = 0; r < BOARD_ROWS; r++)
      for (let c = 0; c < BOARD_COLS; c++) {
        const p = this.board[r][c]
        if (p && p.color === opp) {
          if (this.getRawMoves(new Pos(r, c)).some(m => m.row === king.row && m.col === king.col)) return true
        }
      }
    if (this.isFlyingGeneral()) return true
    return false
  }

  // ---------- valid moves ----------

  getValidMoves(pos: Pos): Pos[] {
    const piece = this.board[pos.row][pos.col]
    if (!piece) return []
    return this.getRawMoves(pos).filter(m => {
      const captured = this.board[m.row][m.col]
      this.board[m.row][m.col] = piece
      this.board[pos.row][pos.col] = null
      const check = this.isInCheck(piece.color)
      this.board[pos.row][pos.col] = piece
      this.board[m.row][m.col] = captured
      return !check
    })
  }

  private hasLegalMoves(color: PieceColor): boolean {
    for (let r = 0; r < BOARD_ROWS; r++)
      for (let c = 0; c < BOARD_COLS; c++) {
        const p = this.board[r][c]
        if (p && p.color === color && this.getValidMoves(new Pos(r, c)).length > 0) return true
      }
    return false
  }

  // ---------- execute / undo ----------

  executeMove(from: Pos, to: Pos): boolean {
    const piece = this.board[from.row][from.col]
    if (!piece) return false
    const captured = this.board[to.row][to.col]

    this.board[to.row][to.col] = piece
    this.board[from.row][from.col] = null

    if (captured) {
      const list = piece.color === PieceColor.RED ? this.capturedByRed : this.capturedByBlack
      list.push(captured)
    }

    this.history.push(new Move(piece, from, to, captured))
    this.turn = this.turn === PieceColor.RED ? PieceColor.BLACK : PieceColor.RED
    this.inCheck = this.isInCheck(this.turn)

    if (!this.hasLegalMoves(this.turn)) {
      this.status = this.turn === PieceColor.RED ? GameStatus.BLACK_WINS : GameStatus.RED_WINS
    }
    return true
  }

  undoMove(): boolean {
    if (this.history.length === 0) return false
    const last = this.history.pop()!

    const piece = this.board[last.to.row][last.to.col]
    this.board[last.from.row][last.from.col] = piece
    this.board[last.to.row][last.to.col] = last.captured

    if (last.captured) {
      const list = last.piece.color === PieceColor.RED ? this.capturedByRed : this.capturedByBlack
      list.pop()
    }

    this.turn = this.turn === PieceColor.RED ? PieceColor.BLACK : PieceColor.RED
    this.status = GameStatus.PLAYING
    this.inCheck = this.isInCheck(this.turn)
    return true
  }
}
