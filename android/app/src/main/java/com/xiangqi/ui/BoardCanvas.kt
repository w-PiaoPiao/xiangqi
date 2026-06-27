package com.xiangqi.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import com.xiangqi.model.*
import kotlin.math.roundToInt

private const val COLS = 9
private const val ROWS = 10
private const val MARGIN_RATIO = 0.08f

data class BoardLayout(
    val left: Float, val top: Float,
    val cellW: Float, val cellH: Float
)

private fun DrawScope.layout(): BoardLayout {
    val left = size.width * MARGIN_RATIO
    val top = size.height * MARGIN_RATIO
    val cellW = (size.width - 2 * left) / (COLS - 1)
    val cellH = (size.height - 2 * top) / (ROWS - 1)
    return BoardLayout(left, top, cellW, cellH)
}

@Composable
fun BoardCanvas(
    board: Array<Array<Piece?>>,
    selectedPos: Pos?,
    validMoves: List<Pos>,
    onCellClick: (Pos) -> Unit
) {
    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(COLS.toFloat() / ROWS.toFloat())
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    val cellW = size.width / COLS
                    val cellH = size.height / ROWS
                    val col = (offset.x / cellW).toInt().coerceIn(0, COLS - 1)
                    val row = (offset.y / cellH).toInt().coerceIn(0, ROWS - 1)
                    onCellClick(Pos(row, col))
                }
            }
    ) {
        drawBackground()
        drawGrid()
        drawPieces(board)
        drawDots(validMoves)
        drawSelection(selectedPos)
    }
}

private fun DrawScope.drawBackground() {
    drawRect(Color(0xFFDEB887), Offset.Zero, size)
}

private fun DrawScope.drawGrid() {
    val l = layout()
    val lineColor = Color(0xFF4A3728)
    val right = l.left + l.cellW * (COLS - 1)
    val bottom = l.top + l.cellH * (ROWS - 1)

    drawRect(lineColor, Offset(l.left, l.top), Size(right - l.left, bottom - l.top), style = Stroke(2f))

    for (row in 0 until ROWS) {
        val y = l.top + row * l.cellH
        drawLine(lineColor, Offset(l.left, y), Offset(right, y))
    }

    for (col in 0 until COLS) {
        val x = l.left + col * l.cellW
        if (col == 0 || col == COLS - 1) {
            drawLine(lineColor, Offset(x, l.top), Offset(x, bottom))
        } else {
            drawLine(lineColor, Offset(x, l.top), Offset(x, l.top + 4 * l.cellH))
            drawLine(lineColor, Offset(x, l.top + 5 * l.cellH), Offset(x, bottom))
        }
    }

    // palace diagonals
    drawLine(lineColor, Offset(l.left + 3 * l.cellW, l.top + 0 * l.cellH), Offset(l.left + 5 * l.cellW, l.top + 2 * l.cellH))
    drawLine(lineColor, Offset(l.left + 5 * l.cellW, l.top + 0 * l.cellH), Offset(l.left + 3 * l.cellW, l.top + 2 * l.cellH))
    drawLine(lineColor, Offset(l.left + 3 * l.cellW, l.top + 7 * l.cellH), Offset(l.left + 5 * l.cellW, l.top + 9 * l.cellH))
    drawLine(lineColor, Offset(l.left + 5 * l.cellW, l.top + 7 * l.cellH), Offset(l.left + 3 * l.cellW, l.top + 9 * l.cellH))
}

private fun DrawScope.drawPieces(board: Array<Array<Piece?>>) {
    val l = layout()
    val radius = minOf(l.cellW, l.cellH) * 0.42f

    for (r in 0 until ROWS) for (c in 0 until COLS) {
        val piece = board[r][c] ?: continue
        val x = l.left + c * l.cellW
        val y = l.top + r * l.cellH
        drawPiece(x, y, radius, piece)
    }
}

private fun DrawScope.drawPiece(x: Float, y: Float, radius: Float, piece: Piece) {
    val isRed = piece.color == PieceColor.RED
    val fill = if (isRed) Color(0xFFC0392B) else Color(0xFF2C3E50)
    val border = if (isRed) Color(0xFFA93226) else Color(0xFF1a252f)

    drawCircle(Color(0x2E000000), radius, Offset(x + 1.5f, y + 2f))
    drawCircle(fill, radius, Offset(x, y))
    drawCircle(border, radius, Offset(x, y), style = Stroke(1.5f))
    drawCircle(Color(0x45FFFFFF), radius * 0.78f, Offset(x, y), style = Stroke(1f))
}

private fun DrawScope.drawSelection(pos: Pos?) {
    if (pos == null) return
    val l = layout()
    val r = minOf(l.cellW, l.cellH) * 0.42f + 4f
    drawCircle(Color(0xFFF1C40F), r, Offset(l.left + pos.col * l.cellW, l.top + pos.row * l.cellH), style = Stroke(3f))
}

private fun DrawScope.drawDots(moves: List<Pos>) {
    if (moves.isEmpty()) return
    val l = layout()
    val dr = maxOf(4f, minOf(l.cellW, l.cellH) * 0.1f)
    for (m in moves) {
        drawCircle(Color(0x8C27AE60), dr, Offset(l.left + m.col * l.cellW, l.top + m.row * l.cellH))
    }
}
