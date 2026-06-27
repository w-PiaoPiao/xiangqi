package com.xiangqi.model

enum class PieceType { GENERAL, ADVISOR, ELEPHANT, HORSE, CHARIOT, CANNON, SOLDIER }

enum class PieceColor { RED, BLACK }

data class Piece(val type: PieceType, val color: PieceColor) {
    val displayName: String
        get() = when (color) {
            PieceColor.RED -> when (type) {
                PieceType.GENERAL -> "帅"
                PieceType.ADVISOR -> "仕"
                PieceType.ELEPHANT -> "相"
                PieceType.HORSE -> "马"
                PieceType.CHARIOT -> "车"
                PieceType.CANNON -> "炮"
                PieceType.SOLDIER -> "兵"
            }
            PieceColor.BLACK -> when (type) {
                PieceType.GENERAL -> "将"
                PieceType.ADVISOR -> "士"
                PieceType.ELEPHANT -> "象"
                PieceType.HORSE -> "马"
                PieceType.CHARIOT -> "车"
                PieceType.CANNON -> "砲"
                PieceType.SOLDIER -> "卒"
            }
        }
}

data class Pos(val row: Int, val col: Int)

data class Move(
    val piece: Piece,
    val from: Pos,
    val to: Pos,
    val captured: Piece? = null
)

enum class GameStatus { PLAYING, RED_WINS, BLACK_WINS }
