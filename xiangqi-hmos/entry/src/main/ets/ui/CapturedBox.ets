import { Piece, PieceColor } from '../model/Piece'

@Component
export struct CapturedBox {
  @Prop label: string = ''
  @Prop pieces: Piece[] = []

  getBgColor(color: PieceColor): string {
    return color === PieceColor.RED ? '#C0392B' : '#2C3E50'
  }

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.label)
          .fontSize(12)
          .fontColor('#8a7a6a')

        Text(`${this.pieces.length}`)
          .fontSize(11)
          .fontColor('#fff')
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#8a7a6a')
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .borderRadius(8)
          .visibility(this.pieces.length === 0 ? Visibility.Hidden : Visibility.Visible)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.pieces.length === 0) {
        Text('-')
          .fontSize(14)
          .fontColor('#c0b5a8')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 4, bottom: 4 })
      } else {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          ForEach(this.pieces, (piece: Piece) => {
            Text(piece.displayName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fff')
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor(this.getBgColor(piece.color))
              .textAlign(TextAlign.Center)
              .margin({ right: 5, bottom: 5 })
          }, (piece: Piece, index: number) => `${piece.color}-${piece.type}-${index}`)
        }
        .width('100%')
      }
    }
    .padding(12)
    .backgroundColor('#FAF7F0')
    .borderRadius(12)
    .layoutWeight(1)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
  }
}
