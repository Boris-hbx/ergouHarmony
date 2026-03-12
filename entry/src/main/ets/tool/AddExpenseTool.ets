import { Tool } from '../model/ToolModels'
import { NextApiClient } from '../service/NextApiClient'
import { CreateExpenseParams } from '../model/ExpenseModels'

export class AddExpenseTool implements Tool {
  name: string = 'add_expense'
  description: string = '记一笔账到Next后端。支持金额、标签、币种和描述'
  parametersSchema: string = '{"type":"object","properties":{"amount":{"type":"number","description":"金额"},"notes":{"type":"string","description":"消费描述/备注"},"tags":{"type":"string","description":"标签，逗号分隔，如\'餐饮,外卖\'"},"currency":{"type":"string","enum":["CAD","CNY","USD"],"description":"币种，默认CAD"},"date":{"type":"string","description":"日期 YYYY-MM-DD，默认今天"}},"required":["amount"]}'

  async execute(args: Record<string, Object>): Promise<string> {
    const amount = Number(args['amount'] || 0)
    if (amount <= 0) {
      return '{"error":"金额必须大于0"}'
    }

    const notes = String(args['notes'] || '')
    const tags = String(args['tags'] || '')
    const currency = String(args['currency'] || 'CAD')

    // 日期默认今天
    let date = String(args['date'] || '')
    if (date.length === 0) {
      const now = new Date()
      const y = now.getFullYear()
      const m = String(now.getMonth() + 1).padStart(2, '0')
      const d = String(now.getDate()).padStart(2, '0')
      date = `${y}-${m}-${d}`
    }

    try {
      const params = new CreateExpenseParams(amount, notes, tags, currency, date)
      const entry = await NextApiClient.createExpense(params)
      return `{"success":true,"id":"${entry.id}","amount":${entry.amount},"notes":"${entry.notes}","tags":"${tags}","currency":"${entry.currency}","date":"${entry.date}"}`
    } catch (err) {
      return `{"error":"${(err as Error).message || '记账失败'}"}`
    }
  }
}
