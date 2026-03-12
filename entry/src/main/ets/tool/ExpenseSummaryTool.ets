import { Tool } from '../model/ToolModels'
import { NextApiClient } from '../service/NextApiClient'

export class ExpenseSummaryTool implements Tool {
  name: string = 'expense_summary'
  description: string = '查询月度记账汇总'
  parametersSchema: string = '{"type":"object","properties":{"month":{"type":"string","description":"月份 YYYY-MM，默认当月"},"currency":{"type":"string","description":"币种筛选"}}}'

  async execute(args: Record<string, Object>): Promise<string> {
    let month = String(args['month'] || '')
    if (month.length === 0) {
      const now = new Date()
      const y = now.getFullYear()
      const m = String(now.getMonth() + 1).padStart(2, '0')
      month = `${y}-${m}`
    }

    const date = `${month}-01`

    try {
      const stats = await NextApiClient.getExpenseStats('month', date)

      // 构建分类 TOP3
      const topCategories: string[] = []
      const sorted = stats.categoryTotals.slice().sort((a, b) => b.amount - a.amount)
      for (let i = 0; i < Math.min(3, sorted.length); i++) {
        topCategories.push(`${sorted[i].category}$${sorted[i].amount.toFixed(2)}`)
      }

      let result = `{"totalAmount":${stats.totalAmount},"entryCount":${stats.entryCount},"period":"${stats.period}","from":"${stats.from}","to":"${stats.to}"`

      if (topCategories.length > 0) {
        result += `,"topCategories":"${topCategories.join(', ')}"`
      }

      if (stats.comparison !== null) {
        const sign = stats.comparison.changePercent >= 0 ? '+' : ''
        result += `,"comparison":"${sign}${stats.comparison.changePercent.toFixed(1)}% vs 上月"`
      }

      result += '}'
      return result
    } catch (err) {
      return `{"error":"${(err as Error).message || '查询统计失败'}"}`
    }
  }
}
