import { GameView } from '../ui/GameView'

@Entry
@Component
struct Index {
  build() {
    Column() {
      GameView()
    }
    .width('100%')
    .height('100%')
  }
}
