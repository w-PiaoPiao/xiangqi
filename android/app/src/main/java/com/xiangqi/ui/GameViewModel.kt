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

    init {
        reset()
    }

    fun onCellClick(pos: Pos) {
        if (status != GameStatus.PLAYING) return

        val piece = board[pos.row][pos.col]

        if (selectedPos == null) {
            if (piece != null && piece.color == turn) {
                selectedPos = pos
                validMoves = engine.getValidMoves(pos)
                syncState()
            }
            return
        }

        val sel = selectedPos!!

        if (pos.row == sel.row && pos.col == sel.col) {
            selectedPos = null
            validMoves = emptyList()
            syncState()
            return
        }

        if (piece != null && piece.color == turn) {
            selectedPos = pos
            validMoves = engine.getValidMoves(pos)
            syncState()
            return
        }

        if (validMoves.any { it.row == pos.row && it.col == pos.col }) {
            engine.executeMove(sel, pos)
            syncState()
            return
        }

        selectedPos = null
        validMoves = emptyList()
        syncState()
    }

    fun undo() {
        engine.undoMove()
        syncState()
    }

    fun reset() {
        engine.initBoard()
        syncState()
    }

    private fun syncState() {
        board = Array(10) { r -> Array(9) { c -> engine.board[r][c] } }
        turn = engine.turn
        selectedPos = engine.selectedPos
        validMoves = engine.validMoves
        inCheck = engine.inCheck
        status = engine.status
        history = engine.history.toList()
        capturedByRed = engine.capturedByRed.toList()
        capturedByBlack = engine.capturedByBlack.toList()
    }
}
