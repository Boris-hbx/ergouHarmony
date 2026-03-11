import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0xFF00

class LoggerClass {
  private formatMsg(tag: string, msg: string): string {
    return `[${tag}] ${msg}`
  }

  debug(tag: string, msg: string, ...args: string[]): void {
    hilog.debug(DOMAIN, tag, this.formatMsg(tag, msg), args)
  }

  info(tag: string, msg: string, ...args: string[]): void {
    hilog.info(DOMAIN, tag, this.formatMsg(tag, msg), args)
  }

  warn(tag: string, msg: string, ...args: string[]): void {
    hilog.warn(DOMAIN, tag, this.formatMsg(tag, msg), args)
  }

  error(tag: string, msg: string, ...args: string[]): void {
    hilog.error(DOMAIN, tag, this.formatMsg(tag, msg), args)
  }
}

export const Logger = new LoggerClass()
