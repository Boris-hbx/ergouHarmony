import { ChatViewModel } from '../viewmodel/ChatViewModel'
import { MessageBubble } from '../components/MessageBubble'
import { ChatInputBar } from '../components/ChatInputBar'
import { router } from '@kit.ArkUI'

@Component
export struct ChatPage {
  @ObjectLink vm: ChatViewModel
  private listScroller: ListScroller = new ListScroller()

  build() {
    Column() {
      // 消息列表
      if (this.vm.messages.length === 0 && !this.vm.isStreaming) {
        this.EmptyState()
      } else {
        this.MessageList()
      }

      // 工具执行提示
      if (this.vm.executingTool.length > 0) {
        Row() {
          LoadingProgress()
            .width(16)
            .height(16)
            .margin({ right: 8 })
          Text(`正在使用工具: ${this.vm.executingTool}`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(8)
      }

      // 错误提示
      if (this.vm.errorMessage.length > 0) {
        Text(this.vm.errorMessage)
          .fontSize(13)
          .fontColor('#FF3B30')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .width('100%')
          .textAlign(TextAlign.Center)
          .backgroundColor('#FFF0F0')
      }

      // 快捷栏
      this.ShortcutBar()

      // 输入栏
      ChatInputBar({
        isStreaming: this.vm.isStreaming,
        onSend: (text: string) => {
          this.vm.sendMessage(text)
          // 延迟滚动到底部
          setTimeout(() => {
            this.scrollToBottom()
          }, 100)
        },
        onStop: () => {
          this.vm.stopGenerating()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ShortcutBar() {
    Scroll() {
      Row({ space: 8 }) {
        Text('记账')
          .fontSize(13)
          .fontColor('#7C4DFF')
          .backgroundColor('#F3EEFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#7C4DFF' })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ExpensePage' })
          })
        Text('任务')
          .fontSize(13)
          .fontColor('#CCCCCC')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#EEEEEE' })
        Text('例行')
          .fontSize(13)
          .fontColor('#CCCCCC')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#EEEEEE' })
        Text('出差')
          .fontSize(13)
          .fontColor('#CCCCCC')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#EEEEEE' })
        Text('英语')
          .fontSize(13)
          .fontColor('#CCCCCC')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#EEEEEE' })
        Text('养生')
          .fontSize(13)
          .fontColor('#CCCCCC')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(18)
          .border({ width: 1, color: '#EEEEEE' })
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 0.5 }, color: '#E0E0E0' })
  }

  @Builder
  EmptyState() {
    Column() {
      Image($r('app.media.avatar_ergou'))
        .width(80)
        .height(80)
        .borderRadius(40)
        .margin({ bottom: 16 })
      Text('二狗')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })
      Text('冷静、专业、高效的私人助手')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 32 })

      // 建议话题
      Column({ space: 8 }) {
        ForEach(
          ['帮我记一笔午饭35块', '今天是星期几', '算一下 156 * 0.85'],
          (topic: string) => {
            Text(topic)
              .fontSize(14)
              .fontColor('#7C4DFF')
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .backgroundColor('#F3EEFF')
              .borderRadius(20)
              .onClick(() => {
                this.vm.sendMessage(topic)
              })
          },
          (topic: string) => topic
        )
      }
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  @Builder
  MessageList() {
    List({ scroller: this.listScroller }) {
      ForEach(this.vm.messages, (msg: import('../model/ChatModels').ChatMessage) => {
        ListItem() {
          MessageBubble({ message: msg })
        }
      }, (msg: import('../model/ChatModels').ChatMessage) => `${msg.id}_${msg.createdAt}`)

      // 流式内容
      if (this.vm.streamingContent.length > 0) {
        ListItem() {
          Row() {
            Image($r('app.media.avatar_ergou'))
              .width(32)
              .height(32)
              .borderRadius(16)
              .margin({ right: 8 })

            Text(this.vm.streamingContent + '▍')
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
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .padding({ left: 16, right: 60, top: 4, bottom: 4 })
        }
      }
    }
    .layoutWeight(1)
    .width('100%')
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .onReachEnd(() => {
      // 到底了
    })
  }

  private scrollToBottom(): void {
    try {
      this.listScroller.scrollToIndex(this.vm.messages.length)
    } catch {
      // 忽略
    }
  }
}
