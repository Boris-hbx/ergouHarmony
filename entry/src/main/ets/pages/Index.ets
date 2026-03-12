import { ChatViewModel } from '../viewmodel/ChatViewModel'
import { ChatPage } from './ChatPage'
import { Session } from '../model/ChatModels'

@Entry
@Component
struct Index {
  @Local vm: ChatViewModel = new ChatViewModel()
  @State showDrawer: boolean = false

  aboutToAppear(): void {
    this.vm.init()
  }

  build() {
    Stack() {
      // 主内容
      Column() {
        // 顶栏
        this.TopBar()

        // 对话页面
        ChatPage({ vm: this.vm })
      }
      .width('100%')
      .height('100%')

      // 侧边抽屉遮罩
      if (this.showDrawer) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#00000066')
          .onClick(() => {
            this.showDrawer = false
          })
      }

      // 侧边抽屉
      if (this.showDrawer) {
        this.DrawerContent()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TopBar() {
    Row() {
      // 汉堡菜单
      Text('≡')
        .fontSize(24)
        .fontColor('#333333')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showDrawer = !this.showDrawer
        })

      Text('二狗')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)

      // 新对话
      Text('+')
        .fontSize(24)
        .fontColor('#007AFF')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.vm.createNewSession()
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
  }

  @Builder
  DrawerContent() {
    Column() {
      // 头部
      Column() {
        Text('🐕')
          .fontSize(36)
          .margin({ bottom: 8 })
        Text('二狗')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('v1.0 鸿蒙版')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 48, bottom: 24 })
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F8F8F8')

      Divider().color('#E0E0E0')

      // 功能菜单
      this.DrawerItem('💬', '对话', true, false)
      this.DrawerItem('💰', '记账', false, false)

      Divider().color('#E0E0E0').margin({ top: 8, bottom: 8 })

      this.DrawerItem('📝', '任务', false, true)
      this.DrawerItem('📅', '例行', false, true)
      this.DrawerItem('✈️', '出差', false, true)
      this.DrawerItem('🔤', '英语', false, true)
      this.DrawerItem('🧘', '养生', false, true)

      Divider().color('#E0E0E0').margin({ top: 8, bottom: 8 })

      // 历史会话列表
      Text('历史对话')
        .fontSize(12)
        .fontColor('#999999')
        .padding({ left: 16, top: 8, bottom: 4 })

      List() {
        ForEach(this.vm.sessions, (session: Session) => {
          ListItem() {
            Row() {
              Text(session.title)
                .fontSize(14)
                .fontColor(session.id === this.vm.currentSessionId ? '#007AFF' : '#333333')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .onClick(() => {
              this.vm.switchSession(session.id)
              this.showDrawer = false
            })
          }
        }, (session: Session) => session.id.toString())
      }
      .layoutWeight(1)
    }
    .width(280)
    .height('100%')
    .backgroundColor('#FFFFFF')
    .position({ x: 0, y: 0 })
    .shadow({
      radius: 16,
      color: '#00000033',
      offsetX: 4
    })
  }

  @Builder
  DrawerItem(icon: string, label: string, active: boolean, disabled: boolean) {
    Row() {
      Text(icon)
        .fontSize(18)
        .margin({ right: 12 })
      Text(label)
        .fontSize(15)
        .fontColor(disabled ? '#CCCCCC' : (active ? '#007AFF' : '#333333'))
        .layoutWeight(1)
      if (active) {
        Text('◄')
          .fontSize(10)
          .fontColor('#007AFF')
      }
      if (disabled) {
        Text('待开发')
          .fontSize(10)
          .fontColor('#CCCCCC')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)
          .border({ width: 0.5, color: '#E0E0E0' })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .enabled(!disabled)
    .onClick(() => {
      if (!disabled) {
        this.showDrawer = false
      }
    })
  }
}
