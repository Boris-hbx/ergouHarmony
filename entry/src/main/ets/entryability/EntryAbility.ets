import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { DatabaseHelper } from '../data/DatabaseHelper'
import { PreferencesUtil } from '../common/PreferencesUtil'

const TAG = Constants.TAG_ENTRY

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      Logger.error(TAG, `设置颜色模式失败 error=${JSON.stringify(err)}`)
    }

    Logger.info(TAG, '应用启动')

    // 初始化 Preferences
    await PreferencesUtil.init(this.context)

    // 初始化数据库
    await DatabaseHelper.init(this.context)

    Logger.info(TAG, '初始化完成')
  }

  onDestroy(): void {
    Logger.info(TAG, '应用销毁')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(TAG, '窗口创建')

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error(TAG, `加载页面失败 error=${JSON.stringify(err)}`)
        return
      }
      Logger.info(TAG, '页面加载成功')
    })
  }

  onWindowStageDestroy(): void {
    Logger.info(TAG, '窗口销毁')
  }

  onForeground(): void {
    Logger.info(TAG, '进入前台')
  }

  onBackground(): void {
    Logger.info(TAG, '进入后台')
  }
}
