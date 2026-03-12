@Component
export struct AddExpenseSheet {
  @State title: string = ''
  @State amount: string = ''
  @State currency: string = 'CAD'
  @State date: string = ''
  @State description: string = ''
  onSave: (amount: number, notes: string, tags: string, currency: string, date: string) => void = () => {}
  onCancel: () => void = () => {}

  aboutToAppear(): void {
    // 默认今天
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    this.date = `${y}-${m}-${d}`
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('记一笔')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor('#999999')
          .onClick(() => {
            this.onCancel()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      // 表单
      Column({ space: 16 }) {
        // 标题
        Column({ space: 4 }) {
          Text('标题')
            .fontSize(13)
            .fontColor('#666666')
          TextInput({ placeholder: '消费标题...', text: this.title })
            .height(40)
            .fontSize(15)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.title = value
            })
        }
        .alignItems(HorizontalAlign.Start)

        // 金额 + 货币
        Column({ space: 4 }) {
          Text('金额')
            .fontSize(13)
            .fontColor('#666666')
          Row({ space: 8 }) {
            TextInput({ placeholder: '0.00', text: this.amount })
              .layoutWeight(1)
              .height(40)
              .fontSize(15)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .type(InputType.NUMBER_DECIMAL)
              .onChange((value: string) => {
                this.amount = value
              })

            Row() {
              Text('CAD')
                .fontSize(12)
                .fontColor(this.currency === 'CAD' ? '#7C4DFF' : '#999999')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .border({ width: 1, color: this.currency === 'CAD' ? '#7C4DFF' : '#E0E0E0' })
                .borderRadius(6)
                .onClick(() => {
                  this.currency = 'CAD'
                })
              Text('CNY')
                .fontSize(12)
                .fontColor(this.currency === 'CNY' ? '#7C4DFF' : '#999999')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .border({ width: 1, color: this.currency === 'CNY' ? '#7C4DFF' : '#E0E0E0' })
                .borderRadius(6)
                .margin({ left: 4 })
                .onClick(() => {
                  this.currency = 'CNY'
                })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)

        // 日期
        Column({ space: 4 }) {
          Text('日期')
            .fontSize(13)
            .fontColor('#666666')
          TextInput({ placeholder: 'YYYY-MM-DD', text: this.date })
            .height(40)
            .fontSize(15)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.date = value
            })
        }
        .alignItems(HorizontalAlign.Start)

        // 描述
        Column({ space: 4 }) {
          Text('描述')
            .fontSize(13)
            .fontColor('#666666')
          TextArea({ placeholder: '添加描述...', text: this.description })
            .height(80)
            .fontSize(14)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.description = value
            })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Blank()

      // 底部按钮
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(22)
          .onClick(() => {
            this.onCancel()
          })

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.amount.trim().length > 0 ? '#7C4DFF' : '#CCCCCC')
          .borderRadius(22)
          .enabled(this.amount.trim().length > 0)
          .onClick(() => {
            const amountNum = parseFloat(this.amount)
            if (amountNum > 0) {
              this.onSave(amountNum, this.title, '', this.currency, this.date)
            }
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
