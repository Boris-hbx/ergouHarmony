import { router } from '@kit.ArkUI'
import { ExpenseViewModel } from '../viewmodel/ExpenseViewModel'
import { ExpenseEntry, TagTotal } from '../model/ExpenseModels'
import { AddExpenseSheet } from '../components/AddExpenseSheet'

@Entry
@Component
struct ExpensePage {
  @State vm: ExpenseViewModel = new ExpenseViewModel()
  @State showAddSheet: boolean = false
  @State actionEntry: ExpenseEntry | null = null
  @State showActionSheet: boolean = false

  aboutToAppear(): void {
    this.vm.init()
  }

  build() {
    Stack() {
      Column() {
        // 顶栏
        this.TopBar()

        // 月份导航
        this.MonthNav()

        // 摘要区
        this.SummaryArea()

        // 标签筛选
        this.TagFilter()

        // 错误提示
        if (this.vm.errorMessage.length > 0) {
          Text(this.vm.errorMessage)
            .fontSize(13)
            .fontColor('#FF3B30')
            .padding(12)
            .width('100%')
            .textAlign(TextAlign.Center)
        }

        // 加载中
        if (this.vm.isLoading) {
          LoadingProgress()
            .width(32)
            .height(32)
            .margin({ top: 40 })
        } else {
          // 记账列表
          this.EntryList()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFBFC')

      // FAB
      Button() {
        Text('+')
          .fontSize(28)
          .fontColor('#FFFFFF')
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor('#7C4DFF')
      .shadow({ radius: 8, color: '#7C4DFF66', offsetY: 4 })
      .position({ right: 20, bottom: 80 })
      .onClick(() => {
        this.showAddSheet = true
      })
      .bindSheet($$this.showAddSheet, this.AddSheetBuilder(), {
        height: SheetSize.MEDIUM,
        dragBar: true
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor('#333333')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          router.back()
        })

      Text('记账')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)

      // 周期切换
      Row() {
        Text('日')
          .fontSize(12)
          .fontColor(this.vm.period === 'day' ? '#7C4DFF' : '#666666')
          .backgroundColor(this.vm.period === 'day' ? '#F3EEFF' : '#F0F0F0')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(14)
          .onClick(() => { this.vm.switchPeriod('day') })
        Text('周')
          .fontSize(12)
          .fontColor(this.vm.period === 'week' ? '#7C4DFF' : '#666666')
          .backgroundColor(this.vm.period === 'week' ? '#F3EEFF' : '#F0F0F0')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(14)
          .onClick(() => { this.vm.switchPeriod('week') })
        Text('月')
          .fontSize(12)
          .fontColor(this.vm.period === 'month' ? '#7C4DFF' : '#666666')
          .backgroundColor(this.vm.period === 'month' ? '#F3EEFF' : '#F0F0F0')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(14)
          .onClick(() => { this.vm.switchPeriod('month') })
      }
      .margin({ right: 8 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  MonthNav() {
    Row() {
      Text('<')
        .fontSize(18)
        .fontColor('#7C4DFF')
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.vm.switchMonth(-1)
        })

      Text(this.vm.getMonthLabel())
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text('>')
        .fontSize(18)
        .fontColor('#7C4DFF')
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.vm.switchMonth(1)
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 4 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SummaryArea() {
    Row() {
      Column() {
        Text('总支出')
          .fontSize(12)
          .fontColor('#999999')
        Text(this.vm.stats ? `$${this.vm.stats.totalAmount.toFixed(2)}` : '$0.00')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Start)

      if (this.vm.stats && this.vm.stats.comparison !== null) {
        Text(this.getComparisonText())
          .fontSize(12)
          .fontColor(this.vm.stats!.comparison!.changePercent >= 0 ? '#FF3B30' : '#34C759')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.vm.stats!.comparison!.changePercent >= 0 ? '#FFF0F0' : '#F0FFF0')
          .borderRadius(12)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TagFilter() {
    if (this.vm.stats && this.vm.stats.tagTotals.length > 0) {
      Scroll() {
        Row({ space: 8 }) {
          // "全部" chip
          Text('全部')
            .fontSize(12)
            .fontColor(this.vm.selectedTag.length === 0 ? '#7C4DFF' : '#666666')
            .backgroundColor(this.vm.selectedTag.length === 0 ? '#F3EEFF' : '#F5F5F5')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .border({ width: 1, color: this.vm.selectedTag.length === 0 ? '#7C4DFF' : '#E0E0E0' })
            .onClick(() => {
              this.vm.filterByTag('')
            })

          ForEach(this.vm.stats!.tagTotals, (tt: TagTotal) => {
            Text(tt.tag)
              .fontSize(12)
              .fontColor(this.vm.selectedTag === tt.tag ? '#7C4DFF' : '#666666')
              .backgroundColor(this.vm.selectedTag === tt.tag ? '#F3EEFF' : '#F5F5F5')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .border({ width: 1, color: this.vm.selectedTag === tt.tag ? '#7C4DFF' : '#E0E0E0' })
              .onClick(() => {
                this.vm.filterByTag(tt.tag)
              })
          }, (tt: TagTotal) => tt.tag)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  EntryList() {
    if (this.vm.filteredEntries.length === 0 && !this.vm.isLoading) {
      Column() {
        Text('暂无记账记录')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 60 })
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      List() {
        ForEach(this.vm.filteredEntries, (entry: ExpenseEntry) => {
          ListItem() {
            Row() {
              Column() {
                Row({ space: 6 }) {
                  Text(entry.notes || '未命名')
                    .fontSize(15)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  ForEach(entry.tags, (tag: string) => {
                    Text(tag)
                      .fontSize(10)
                      .fontColor('#7C4DFF')
                      .backgroundColor('#F3EEFF')
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .borderRadius(3)
                  }, (tag: string) => tag)
                }

                Text(entry.date)
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text(`${entry.currency === 'CNY' ? '¥' : '$'}${entry.amount.toFixed(2)}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 12, right: 12, top: 4 })
            .onClick(() => {
              this.actionEntry = entry
              this.showActionSheet = true
            })
          }
        }, (entry: ExpenseEntry) => entry.id)
      }
      .layoutWeight(1)
      .width('100%')
      .listDirection(Axis.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  AddSheetBuilder() {
    AddExpenseSheet({
      onSave: async (amount: number, notes: string, tags: string, currency: string, date: string) => {
        const success = await this.vm.createExpense(amount, notes, tags, currency, date)
        if (success) {
          this.showAddSheet = false
        }
      },
      onCancel: () => {
        this.showAddSheet = false
      }
    })
  }

  private getComparisonText(): string {
    if (this.vm.stats && this.vm.stats.comparison !== null) {
      const pct = this.vm.stats.comparison!.changePercent
      const sign = pct >= 0 ? '+' : ''
      return `${sign}${pct.toFixed(1)}% vs 上月`
    }
    return ''
  }
}
