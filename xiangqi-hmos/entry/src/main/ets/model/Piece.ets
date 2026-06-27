export enum PieceType {
  GENERAL = 'general',
  ADVISOR = 'advisor',
  ELEPHANT = 'elephant',
  HORSE = 'horse',
  CHARIOT = 'chariot',
  CANNON = 'cannon',
  SOLDIER = 'soldier'
}

export enum PieceColor {
  RED = 'red',
  BLACK = 'black'
}

export class Piece {
  type: PieceType
  color: PieceColor

  constructor(type: PieceType, color: PieceColor) {
    this.type = type
    this.color = color
  }

  get displayName(): string {
    if (this.color === PieceColor.RED) {
      switch (this.type) {
        case PieceType.GENERAL: return '帅'
        case PieceType.ADVISOR: return '仕'
        case PieceType.ELEPHANT: return '相'
        case PieceType.HORSE: return '马'
        case PieceType.CHARIOT: return '车'
        case PieceType.CANNON: return '炮'
        case PieceType.SOLDIER: return '兵'
      }
    } else {
      switch (this.type) {
        case PieceType.GENERAL: return '将'
        case PieceType.ADVISOR: return '士'
        case PieceType.ELEPHANT: return '象'
        case PieceType.HORSE: return '马'
        case PieceType.CHARIOT: return '车'
        case PieceType.CANNON: return '砲'
        case PieceType.SOLDIER: return '卒'
      }
    }
  }
}

export class Pos {
  row: number
  col: number

  constructor(row: number, col: number) {
    this.row = row
    this.col = col
  }
}

export class Move {
  piece: Piece
  from: Pos
  to: Pos
  captured: Piece | null

  constructor(piece: Piece, from: Pos, to: Pos, captured: Piece | null) {
    this.piece = piece
    this.from = from
    this.to = to
    this.captured = captured
  }
}

export enum GameStatus {
  PLAYING = 'playing',
  RED_WINS = 'red_wins',
  BLACK_WINS = 'black_wins'
}
