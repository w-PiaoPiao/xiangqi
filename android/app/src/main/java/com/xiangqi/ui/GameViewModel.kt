package com.xiangqi.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.xiangqi.engine.GameEngine
import com.xiangqi.model.*

class GameViewModel : ViewModel() {

    private val engine = GameEngine()

    var board: Array<Array<Piece?>> by mutableStateOf(Array(10) { Array(9) { null } })
        private set
    var turn: PieceColor by mutableStateOf(PieceColor.RED)
        private set
    var selectedPos: Pos? by mutableStateOf(null)
        private set
    var validMoves: List<Pos> by mutableStateOf(emptyList())
        private set
    var inCheck: Boolean by mutableStateOf(false)
        private set
    var status: GameStatus by mutableStateOf(GameStatus.PLAYING)
        private set
    var history: List<Move> by mutableStateOf(emptyList())
        private set
    var capturedByRed: List<Piece> by mutableStateOf(emptyList())
        private set
    var capturedByBlack: List<Piece> by mutableStateOf(emptyList())
        private set
    var debugLastTap: String by mutableStateOf("")
        private set

    init {
        reset()
    }

    fun onCellClick(pos: Pos) {
        if (status != GameStatus.PLAYING) return

        debugLastTap = "点击 (${pos.row},${pos.col})"

        val piece = board[pos.row][pos.col]

        if (selectedPos == null) {
            if (piece != null && piece.color == turn) {
                debugLastTap = "选中 (${pos.row},${pos.col}) ${piece.displayName}"
                selectedPos = pos
                validMoves = engine.getValidMoves(pos)
            }
            return
        }

        val sel = selectedPos!!

        if (pos.row == sel.row && pos.col == sel.col) {
            debugLastTap = "取消选中"
            selectedPos = null
            validMoves = emptyList()
            return
        }

        if (piece != null && piece.color == turn) {
            debugLastTap = "切换选中 (${pos.row},${pos.col}) ${piece.displayName}"
            selectedPos = pos
            validMoves = engine.getValidMoves(pos)
            return
        }

        if (validMoves.any { it.row == pos.row && it.col == pos.col }) {
            debugLastTap = "走棋 (${sel.row},${sel.col})→(${pos.row},${pos.col})"
            engine.executeMove(sel, pos)
            selectedPos = null
            validMoves = emptyList()
            syncBoard()
            return
        }

        debugLastTap = "无效点击 (${pos.row},${pos.col})"
        selectedPos = null
        validMoves = emptyList()
    }

    fun undo() {
        engine.undoMove()
        selectedPos = null
        validMoves = emptyList()
        syncBoard()
    }

    fun reset() {
        engine.initBoard()
        selectedPos = null
        validMoves = emptyList()
        syncBoard()
    }

    private fun syncBoard() {
        board = Array(10) { r -> Array(9) { c -> engine.board[r][c] } }
        turn = engine.turn
        inCheck = engine.inCheck
        status = engine.status
        history = engine.history.toList()
        capturedByRed = engine.capturedByRed.toList()
        capturedByBlack = engine.capturedByBlack.toList()
    }
}
