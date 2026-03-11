import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Logger } from './Logger'
import { Constants } from './Constants'

const TAG = Constants.TAG_PREFS

class PreferencesUtilClass {
  private prefs: preferences.Preferences | null = null

  async init(context: common.BaseContext): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, Constants.PREFERENCES_NAME)
      Logger.info(TAG, '初始化成功')
    } catch (err) {
      Logger.error(TAG, `初始化失败 error=${JSON.stringify(err)}`)
    }
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.prefs) {
      Logger.warn(TAG, '未初始化，返回默认值')
      return defaultValue
    }
    try {
      const value = await this.prefs.get(key, defaultValue)
      return value as string
    } catch (err) {
      Logger.error(TAG, `getString 失败 key=${key} error=${JSON.stringify(err)}`)
      return defaultValue
    }
  }

  async putString(key: string, value: string): Promise<void> {
    if (!this.prefs) {
      Logger.warn(TAG, '未初始化，无法写入')
      return
    }
    try {
      await this.prefs.put(key, value)
      await this.prefs.flush()
    } catch (err) {
      Logger.error(TAG, `putString 失败 key=${key} error=${JSON.stringify(err)}`)
    }
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.prefs) {
      return defaultValue
    }
    try {
      const value = await this.prefs.get(key, defaultValue)
      return value as number
    } catch (err) {
      Logger.error(TAG, `getNumber 失败 key=${key} error=${JSON.stringify(err)}`)
      return defaultValue
    }
  }

  async putNumber(key: string, value: number): Promise<void> {
    if (!this.prefs) {
      return
    }
    try {
      await this.prefs.put(key, value)
      await this.prefs.flush()
    } catch (err) {
      Logger.error(TAG, `putNumber 失败 key=${key} error=${JSON.stringify(err)}`)
    }
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.prefs) {
      return defaultValue
    }
    try {
      const value = await this.prefs.get(key, defaultValue)
      return value as boolean
    } catch (err) {
      Logger.error(TAG, `getBoolean 失败 key=${key} error=${JSON.stringify(err)}`)
      return defaultValue
    }
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.prefs) {
      return
    }
    try {
      await this.prefs.put(key, value)
      await this.prefs.flush()
    } catch (err) {
      Logger.error(TAG, `putBoolean 失败 key=${key} error=${JSON.stringify(err)}`)
    }
  }

  async delete(key: string): Promise<void> {
    if (!this.prefs) {
      return
    }
    try {
      await this.prefs.delete(key)
      await this.prefs.flush()
    } catch (err) {
      Logger.error(TAG, `delete 失败 key=${key} error=${JSON.stringify(err)}`)
    }
  }

  async has(key: string): Promise<boolean> {
    if (!this.prefs) {
      return false
    }
    try {
      return await this.prefs.has(key)
    } catch (err) {
      Logger.error(TAG, `has 失败 key=${key} error=${JSON.stringify(err)}`)
      return false
    }
  }
}

export const PreferencesUtil = new PreferencesUtilClass()
