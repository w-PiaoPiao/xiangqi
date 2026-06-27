package com.xiangqi.engine

import com.xiangqi.model.*

class GameEngine {

    val board: Array<Array<Piece?>> = Array(10) { Array(9) { null } }
    var turn: PieceColor = PieceColor.RED
    var selectedPos: Pos? = null
    var validMoves: List<Pos> = emptyList()
    var inCheck: Boolean = false
    var status: GameStatus = GameStatus.PLAYING
    val history: MutableList<Move> = mutableListOf()
    val capturedByRed: MutableList<Piece> = mutableListOf()
    val capturedByBlack: MutableList<Piece> = mutableListOf()

    fun initBoard() {
        for (r in 0 until 10) for (c in 0 until 9) board[r][c] = null

        val backRank = listOf(
            PieceType.CHARIOT, PieceType.HORSE, PieceType.ELEPHANT,
            PieceType.ADVISOR, PieceType.GENERAL, PieceType.ADVISOR,
            PieceType.ELEPHANT, PieceType.HORSE, PieceType.CHARIOT
        )

        for (c in 0 until 9) board[0][c] = Piece(backRank[c], PieceColor.BLACK)
        board[2][1] = Piece(PieceType.CANNON, PieceColor.BLACK)
        board[2][7] = Piece(PieceType.CANNON, PieceColor.BLACK)
        for (c in 0 until 9 step 2) board[3][c] = Piece(PieceType.SOLDIER, PieceColor.BLACK)

        for (c in 0 until 9) board[9][c] = Piece(backRank[c], PieceColor.RED)
        board[7][1] = Piece(PieceType.CANNON, PieceColor.RED)
        board[7][7] = Piece(PieceType.CANNON, PieceColor.RED)
        for (c in 0 until 9 step 2) board[6][c] = Piece(PieceType.SOLDIER, PieceColor.RED)

        turn = PieceColor.RED
        selectedPos = null
        validMoves = emptyList()
        inCheck = false
        status = GameStatus.PLAYING
        history.clear()
        capturedByRed.clear()
        capturedByBlack.clear()
    }

    // ---------- helpers ----------

    private fun inBoard(r: Int, c: Int) = r in 0..9 && c in 0..8

    private fun findKing(color: PieceColor): Pos? {
        for (r in 0 until 10) for (c in 0 until 9) {
            val p = board[r][c]
            if (p?.type == PieceType.GENERAL && p.color == color) return Pos(r, c)
        }
        return null
    }

    private fun isFlyingGeneral(): Boolean {
        val rk = findKing(PieceColor.RED) ?: return false
        val bk = findKing(PieceColor.BLACK) ?: return false
        if (rk.col != bk.col) return false
        val minR = minOf(rk.row, bk.row)
        val maxR = maxOf(rk.row, bk.row)
        for (r in minR + 1 until maxR) if (board[r][rk.col] != null) return false
        return true
    }

    // ---------- raw moves per piece type ----------

    private fun getGeneralMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        val (minR, maxR) = if (piece.color == PieceColor.RED) 7 to 9 else 0 to 2
        for ((dr, dc) in listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1)) {
            val nr = row + dr; val nc = col + dc
            if (nr !in minR..maxR || nc !in 3..5) continue
            val t = board[nr][nc]
            if (t == null || t.color != piece.color) moves.add(Pos(nr, nc))
        }
        return moves
    }

    private fun getAdvisorMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        val (minR, maxR) = if (piece.color == PieceColor.RED) 7 to 9 else 0 to 2
        for ((dr, dc) in listOf(-1 to -1, -1 to 1, 1 to -1, 1 to 1)) {
            val nr = row + dr; val nc = col + dc
            if (nr !in minR..maxR || nc !in 3..5) continue
            val t = board[nr][nc]
            if (t == null || t.color != piece.color) moves.add(Pos(nr, nc))
        }
        return moves
    }

    private fun getElephantMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        val isRed = piece.color == PieceColor.RED
        val dirs = listOf(-2 to -2, -2 to 2, 2 to -2, 2 to 2)
        val eyes = listOf(-1 to -1, -1 to 1, 1 to -1, 1 to 1)
        for (i in 0 until 4) {
            val nr = row + dirs[i].first; val nc = col + dirs[i].second
            val er = row + eyes[i].first; val ec = col + eyes[i].second
            if (!inBoard(nr, nc)) continue
            if (isRed && nr < 5) continue
            if (!isRed && nr > 4) continue
            if (board[er][ec] != null) continue
            val t = board[nr][nc]
            if (t == null || t.color != piece.color) moves.add(Pos(nr, nc))
        }
        return moves
    }

    private fun getHorseMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        val jumps = listOf(
            -2 to -1, -2 to 1, -1 to -2, -1 to 2,
            1 to -2, 1 to 2, 2 to -1, 2 to 1
        )
        val legs = listOf(
            -1 to 0, -1 to 0, 0 to -1, 0 to 1,
            0 to -1, 0 to 1, 1 to 0, 1 to 0
        )
        for (i in 0 until 8) {
            val nr = row + jumps[i].first; val nc = col + jumps[i].second
            val lr = row + legs[i].first; val lc = col + legs[i].second
            if (!inBoard(nr, nc)) continue
            if (board[lr][lc] != null) continue
            val t = board[nr][nc]
            if (t == null || t.color != piece.color) moves.add(Pos(nr, nc))
        }
        return moves
    }

    private fun getChariotMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        for ((dr, dc) in listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1)) {
            var nr = row + dr; var nc = col + dc
            while (inBoard(nr, nc)) {
                val t = board[nr][nc]
                if (t == null) moves.add(Pos(nr, nc))
                else { if (t.color != piece.color) moves.add(Pos(nr, nc)); break }
                nr += dr; nc += dc
            }
        }
        return moves
    }

    private fun getCannonMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        for ((dr, dc) in listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1)) {
            var nr = row + dr; var nc = col + dc
            var jumped = false
            while (inBoard(nr, nc)) {
                val t = board[nr][nc]
                if (!jumped) {
                    if (t == null) moves.add(Pos(nr, nc))
                    else jumped = true
                } else {
                    if (t != null) {
                        if (t.color != piece.color) moves.add(Pos(nr, nc))
                        break
                    }
                }
                nr += dr; nc += dc
            }
        }
        return moves
    }

    private fun getSoldierMoves(row: Int, col: Int, piece: Piece): List<Pos> {
        val moves = mutableListOf<Pos>()
        val isRed = piece.color == PieceColor.RED
        val fwd = if (isRed) -1 else 1
        val crossed = if (isRed) row <= 4 else row >= 5
        val nr = row + fwd
        if (inBoard(nr, col)) {
            val t = board[nr][col]
            if (t == null || t.color != piece.color) moves.add(Pos(nr, col))
        }
        if (crossed) {
            for (dc in listOf(-1, 1)) {
                val nc = col + dc
                if (!inBoard(row, nc)) continue
                val t = board[row][nc]
                if (t == null || t.color != piece.color) moves.add(Pos(row, nc))
            }
        }
        return moves
    }

    private fun getRawMoves(pos: Pos): List<Pos> {
        val p = board[pos.row][pos.col] ?: return emptyList()
        return when (p.type) {
            PieceType.GENERAL -> getGeneralMoves(pos.row, pos.col, p)
            PieceType.ADVISOR -> getAdvisorMoves(pos.row, pos.col, p)
            PieceType.ELEPHANT -> getElephantMoves(pos.row, pos.col, p)
            PieceType.HORSE -> getHorseMoves(pos.row, pos.col, p)
            PieceType.CHARIOT -> getChariotMoves(pos.row, pos.col, p)
            PieceType.CANNON -> getCannonMoves(pos.row, pos.col, p)
            PieceType.SOLDIER -> getSoldierMoves(pos.row, pos.col, p)
        }
    }

    // ---------- check detection ----------

    fun isInCheck(color: PieceColor): Boolean {
        val king = findKing(color) ?: return true
        val opp = if (color == PieceColor.RED) PieceColor.BLACK else PieceColor.RED
        for (r in 0 until 10) for (c in 0 until 9) {
            val p = board[r][c] ?: continue
            if (p.color != opp) continue
            if (getRawMoves(Pos(r, c)).any { it.row == king.row && it.col == king.col }) return true
        }
        if (isFlyingGeneral()) return true
        return false
    }

    // ---------- valid moves (filter self-check) ----------

    fun getValidMoves(pos: Pos): List<Pos> {
        val piece = board[pos.row][pos.col] ?: return emptyList()
        return getRawMoves(pos).filter { m ->
            val captured = board[m.row][m.col]
            board[m.row][m.col] = piece
            board[pos.row][pos.col] = null
            val check = isInCheck(piece.color)
            board[pos.row][pos.col] = piece
            board[m.row][m.col] = captured
            !check
        }
    }

    private fun hasLegalMoves(color: PieceColor): Boolean {
        for (r in 0 until 10) for (c in 0 until 9) {
            val p = board[r][c]
            if (p != null && p.color == color && getValidMoves(Pos(r, c)).isNotEmpty()) return true
        }
        return false
    }

    // ---------- execute / undo ----------

    fun executeMove(from: Pos, to: Pos): Boolean {
        val piece = board[from.row][from.col] ?: return false
        val captured = board[to.row][to.col]

        board[to.row][to.col] = piece
        board[from.row][from.col] = null

        if (captured != null) {
            val list = if (piece.color == PieceColor.RED) capturedByRed else capturedByBlack
            list.add(captured)
        }

        history.add(Move(piece, from, to, captured))
        turn = if (turn == PieceColor.RED) PieceColor.BLACK else PieceColor.RED
        selectedPos = null
        validMoves = emptyList()
        inCheck = isInCheck(turn)

        if (!hasLegalMoves(turn)) {
            status = if (turn == PieceColor.RED) GameStatus.BLACK_WINS else GameStatus.RED_WINS
        }

        return true
    }

    fun undoMove(): Boolean {
        if (history.isEmpty()) return false
        val last = history.removeLast()

        val piece = board[last.to.row][last.to.col]
        board[last.from.row][last.from.col] = piece
        board[last.to.row][last.to.col] = last.captured

        if (last.captured != null) {
            val list = if (last.piece.color == PieceColor.RED) capturedByRed else capturedByBlack
            list.removeLast()
        }

        turn = if (turn == PieceColor.RED) PieceColor.BLACK else PieceColor.RED
        selectedPos = null
        validMoves = emptyList()
        status = GameStatus.PLAYING
        inCheck = isInCheck(turn)
        return true
    }

    fun reset() {
        initBoard()
    }
}
