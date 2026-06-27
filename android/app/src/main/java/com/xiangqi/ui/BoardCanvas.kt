package com.xiangqi.ui

import android.graphics.Paint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.changedToUp
import androidx.compose.ui.input.pointer.pointerInput
import com.xiangqi.model.*
import kotlin.math.roundToInt

private const val COLS = 9
private const val ROWS = 10
private const val MARGIN_RATIO = 0.05f

data class BoardLayout(
    val left: Float, val top: Float,
    val cellW: Float, val cellH: Float
)

private fun calcLayout(w: Float, h: Float): BoardLayout {
    val left = w * MARGIN_RATIO
    val top = h * MARGIN_RATIO
    val cellW = (w - 2 * left) / (COLS - 1)
    val cellH = (h - 2 * top) / (ROWS - 1)
    return BoardLayout(left, top, cellW, cellH)
}

private fun DrawScope.layout(): BoardLayout = calcLayout(size.width, size.height)

@Composable
fun BoardCanvas(
    board: Array<Array<Piece?>>,
    selectedPos: Pos?,
    validMoves: List<Pos>,
    onCellClick: (Pos) -> Unit
) {
    val textPaint = remember {
        Paint().apply {
            color = android.graphics.Color.WHITE
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
            isFakeBoldText = true
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(COLS.toFloat() / ROWS.toFloat())
            .background(Color(0xFFDEB887))
            .pointerInput(Unit) {
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent(PointerEventPass.Initial)
                        val change = event.changes.firstOrNull() ?: continue
                        if (!change.previousPressed && change.pressed) {
                            val l = calcLayout(size.width.toFloat(), size.height.toFloat())
                            val col = ((change.position.x - l.left) / l.cellW).roundToInt().coerceIn(0, COLS - 1)
                            val row = ((change.position.y - l.top) / l.cellH).roundToInt().coerceIn(0, ROWS - 1)
                            onCellClick(Pos(row, col))
                            change.consume()
                        }
                    }
                }
            }
    ) {
        Canvas(Modifier.fillMaxSize()) {
            drawGrid()
            drawPieces(board, textPaint)
            drawDots(validMoves)
            drawSelection(selectedPos)
        }
    }
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

    drawLine(lineColor, Offset(l.left + 3 * l.cellW, l.top), Offset(l.left + 5 * l.cellW, l.top + 2 * l.cellH))
    drawLine(lineColor, Offset(l.left + 5 * l.cellW, l.top), Offset(l.left + 3 * l.cellW, l.top + 2 * l.cellH))
    drawLine(lineColor, Offset(l.left + 3 * l.cellW, l.top + 7 * l.cellH), Offset(l.left + 5 * l.cellW, l.top + 9 * l.cellH))
    drawLine(lineColor, Offset(l.left + 5 * l.cellW, l.top + 7 * l.cellH), Offset(l.left + 3 * l.cellW, l.top + 9 * l.cellH))
}

private fun DrawScope.drawPieces(board: Array<Array<Piece?>>, textPaint: Paint) {
    val l = layout()
    val radius = minOf(l.cellW, l.cellH) * 0.42f
    textPaint.textSize = radius * 1.15f

    for (r in 0 until ROWS) for (c in 0 until COLS) {
        val piece = board[r][c] ?: continue
        val cx = l.left + c * l.cellW
        val cy = l.top + r * l.cellH
        val isRed = piece.color == PieceColor.RED
        val fill = if (isRed) Color(0xFFC0392B) else Color(0xFF2C3E50)
        val border = if (isRed) Color(0xFFA93226) else Color(0xFF1a252f)

        drawCircle(Color(0x2E000000), radius, Offset(cx + 1.5f, cy + 2f))
        drawCircle(fill, radius, Offset(cx, cy))
        drawCircle(border, radius, Offset(cx, cy), style = Stroke(1.5f))
        drawCircle(Color(0x45FFFFFF), radius * 0.78f, Offset(cx, cy), style = Stroke(1f))

        drawContext.canvas.nativeCanvas.drawText(
            piece.displayName, cx,
            cy + radius * 0.4f, textPaint
        )
    }
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
