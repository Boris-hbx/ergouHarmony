@Component
export struct ChatInputBar {
  @Prop isStreaming: boolean = false
  @State inputText: string = ''
  onSend: (text: string) => void = () => {}
  onStop: () => void = () => {}

  build() {
    Row() {
      TextInput({ text: this.inputText, placeholder: '说点什么...' })
        .layoutWeight(1)
        .height(40)
        .fontSize(15)
        .borderRadius(20)
        .backgroundColor('#F5F5F5')
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.inputText = value
        })
        .onSubmit(() => {
          this.handleSend()
        })

      if (this.isStreaming) {
        // 停止按钮
        Button() {
          Rect()
            .width(14)
            .height(14)
            .fill('#FFFFFF')
            .radius(2)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#FF3B30')
        .margin({ left: 8 })
        .onClick(() => {
          this.onStop()
        })
      } else {
        // 发送按钮
        Button() {
          SymbolGlyph($r('sys.symbol.arrow_up'))
            .fontSize(18)
            .fontColor([this.inputText.trim().length > 0 ? '#FFFFFF' : '#CCCCCC'])
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.inputText.trim().length > 0 ? '#007AFF' : '#E5E5E5')
        .margin({ left: 8 })
        .enabled(this.inputText.trim().length > 0)
        .onClick(() => {
          this.handleSend()
        })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 24 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 0.5 }, color: '#E0E0E0' })
  }

  private handleSend(): void {
    const text = this.inputText.trim()
    if (text.length > 0 && !this.isStreaming) {
      this.onSend(text)
      this.inputText = ''
    }
  }
}
