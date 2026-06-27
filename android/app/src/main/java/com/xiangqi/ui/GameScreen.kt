package com.xiangqi.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.xiangqi.model.*

@Composable
fun GameScreen(viewModel: GameViewModel = viewModel()) {
    val board by viewModel::board
    val selectedPos by viewModel::selectedPos
    val validMoves by viewModel::validMoves
    val status by viewModel::status
    val turn by viewModel::turn
    val inCheck by viewModel::inCheck
    val history by viewModel::history
    val capturedByRed by viewModel::capturedByRed
    val capturedByBlack by viewModel::capturedByBlack
    val debugLastTap by viewModel::debugLastTap

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F0E8))
            .systemBarsPadding()
            .padding(horizontal = 12.dp, vertical = 8.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "中 国 象 棋",
            fontSize = 20.sp,
            fontWeight = FontWeight(600),
            color = Color(0xFF4A3728),
            letterSpacing = 4.sp,
            modifier = Modifier.padding(bottom = 4.dp)
        )

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(18.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = debugLastTap.ifEmpty { "等待点击..." },
                fontSize = 12.sp,
                color = Color(0xFF666666)
            )
        }

        BoardCanvas(
            board = board,
            selectedPos = selectedPos,
            validMoves = validMoves,
            onCellClick = { viewModel.onCellClick(it) }
        )

        Spacer(Modifier.height(8.dp))

        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            CapturedBox("红方吃子", capturedByRed, Modifier.weight(1f))
            CapturedBox("黑方吃子", capturedByBlack, Modifier.weight(1f))
        }

        Spacer(Modifier.height(8.dp))

        StatusBar(turn, inCheck, status)

        Spacer(Modifier.height(8.dp))

        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { viewModel.reset() }, modifier = Modifier.weight(1f)) { Text("重新开始") }
            OutlinedButton(onClick = { viewModel.undo() }, modifier = Modifier.weight(1f)) { Text("悔棋") }
        }

        Spacer(Modifier.height(8.dp))

        MoveHistoryPanel(history)
    }
}

@Composable
private fun CapturedBox(label: String, pieces: List<Piece>, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .background(Color(0xFFFAF7F0), shape = MaterialTheme.shapes.small)
            .padding(6.dp)
    ) {
        Text(label, fontSize = 11.sp, color = Color(0xFF8a7a6a))
        Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
            pieces.forEach { p ->
                val bg = if (p.color == PieceColor.RED) Color(0xFFC0392B) else Color(0xFF2C3E50)
                Surface(shape = MaterialTheme.shapes.extraSmall, color = bg, modifier = Modifier.size(24.dp)) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(p.displayName, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusBar(turn: PieceColor, inCheck: Boolean, status: GameStatus) {
    val bg = when {
        status != GameStatus.PLAYING -> Color(0xFFE8F5E9)
        inCheck -> Color(0xFFFDE8E8)
        else -> Color(0xFFFAF7F0)
    }
    val text = when (status) {
        GameStatus.RED_WINS -> "🏆 红方胜！"
        GameStatus.BLACK_WINS -> "🏆 黑方胜！"
        else -> if (turn == PieceColor.RED) "红方走棋" else "黑方走棋"
    }

    Surface(Modifier.fillMaxWidth(), color = bg, shape = MaterialTheme.shapes.small) {
        Row(
            Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(text, fontSize = 14.sp)
            if (inCheck && status == GameStatus.PLAYING) {
                Text("⚠️ 将军！", color = Color(0xFFC0392B), fontWeight = FontWeight(600), fontSize = 14.sp)
            }
        }
    }
}

private fun formatMove(move: Move): String {
    val name = move.piece.displayName
    val fromCol = 9 - move.from.col
    val toCol = 9 - move.to.col
    val dr = move.to.row - move.from.row
    val isRed = move.piece.color == PieceColor.RED
    val fwd = if (isRed) dr < 0 else dr > 0
    val dir = when {
        dr == 0 -> "平"
        fwd -> "进"
        else -> "退"
    }
    return "$name$fromCol$dir$toCol"
}

@Composable
private fun MoveHistoryPanel(history: List<Move>) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(Color(0xFFFAF7F0), shape = MaterialTheme.shapes.small)
            .padding(8.dp)
            .heightIn(max = 130.dp)
    ) {
        Text("走棋记录", fontSize = 12.sp, color = Color(0xFF8a7a6a))
        Spacer(Modifier.height(4.dp))
        val scroll = rememberScrollState()
        Column(Modifier.verticalScroll(scroll)) {
            for (i in history.indices) {
                val m = history[i]
                val col = if (m.piece.color == PieceColor.RED) Color(0xFFC0392B) else Color(0xFF2C3E50)
                val line = buildString {
                    if (i % 2 == 0) append("${i / 2 + 1}. ")
                    append(formatMove(m))
                    if (i % 2 == 1) append("\n") else append("  ")
                }
                Text(line, fontSize = 13.sp, color = col, fontFamily = FontFamily.Monospace)
                LaunchedEffect(history.size) { scroll.animateScrollTo(scroll.maxValue) }
            }
        }
    }
}
