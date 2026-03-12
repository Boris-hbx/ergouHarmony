import { ChatMessage } from '../model/ChatModels'

@Component
export struct MessageBubble {
  @Prop message: ChatMessage
  @Prop isStreaming: boolean = false

  build() {
    if (this.message.role === 'user') {
      this.UserBubble()
    } else if (this.message.role === 'assistant') {
      this.AssistantBubble()
    }
    // tool 消息不渲染
  }

  @Builder
  UserBubble() {
    Row() {
      Blank()
      Text(this.message.content)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#7C4DFF')
        .borderRadius({
          topLeft: 16,
          topRight: 4,
          bottomLeft: 16,
          bottomRight: 16
        })
        .constraintSize({ maxWidth: '75%' })
        .wordBreak(WordBreak.BREAK_ALL)
    }
    .width('100%')
    .padding({ left: 60, right: 16, top: 4, bottom: 4 })
  }

  @Builder
  AssistantBubble() {
    Row() {
      // 二狗头像
      Image($r('app.media.avatar_ergou'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .margin({ right: 8 })

      Text(this.message.content)
        .fontSize(15)
        .fontColor('#333333')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#F0F0F0')
        .borderRadius({
          topLeft: 4,
          topRight: 16,
          bottomLeft: 16,
          bottomRight: 16
        })
        .constraintSize({ maxWidth: '70%' })
        .wordBreak(WordBreak.BREAK_ALL)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 16, right: 60, top: 4, bottom: 4 })
  }
}
