import { http } from '@kit.NetworkKit'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { PreferencesUtil } from '../common/PreferencesUtil'
import {
  ExpenseEntry,
  ExpenseStats,
  TagTotal,
  CategoryTotal,
  DailyAmount,
  Comparison,
  CreateExpenseParams
} from '../model/ExpenseModels'

const TAG = Constants.TAG_EXPENSE

class NextApiClientClass {
  private async request(method: http.RequestMethod, path: string, body?: string): Promise<string> {
    const token = await PreferencesUtil.getString(Constants.KEY_SESSION_TOKEN, '')
    const httpRequest = http.createHttp()

    try {
      const response = await httpRequest.request(Constants.NEXT_API_BASE_URL + path, {
        method: method,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        extraData: body || '',
        expectDataType: http.HttpDataType.STRING
      })

      const code = response.responseCode
      const result = response.result as string

      if (code === 401) {
        throw new Error('认证失败，请重新登录')
      }
      if (code >= 400) {
        throw new Error(`HTTP ${code}: ${result}`)
      }

      return result
    } catch (err) {
      const errMsg = (err as Error).message || '网络请求失败'
      Logger.error(TAG, `API 请求失败 path=${path} error=${errMsg}`)
      throw new Error(errMsg)
    } finally {
      httpRequest.destroy()
    }
  }

  async getExpenseStats(period: string, date: string): Promise<ExpenseStats> {
    const result = await this.request(http.RequestMethod.GET, `/expenses/stats?period=${period}&date=${date}`)
    const json = JSON.parse(result) as Record<string, Object>
    return this.parseStats(json)
  }

  async getExpenses(month: string, tag?: string): Promise<ExpenseEntry[]> {
    let path = `/expenses/?month=${month}`
    if (tag && tag.length > 0) {
      path += `&tag=${encodeURIComponent(tag)}`
    }
    const result = await this.request(http.RequestMethod.GET, path)
    const json = JSON.parse(result) as Record<string, Object>
    const items = json['expenses'] as Object[]
    if (!items) {
      return []
    }
    const entries: ExpenseEntry[] = []
    for (const item of items) {
      entries.push(this.parseEntry(item as Record<string, Object>))
    }
    return entries
  }

  async createExpense(params: CreateExpenseParams): Promise<ExpenseEntry> {
    const body = JSON.stringify({
      amount: params.amount,
      notes: params.notes,
      tags: params.tags,
      currency: params.currency,
      date: params.date
    })
    const result = await this.request(http.RequestMethod.POST, '/expenses/', body)
    const json = JSON.parse(result) as Record<string, Object>
    const expense = json['expense'] as Record<string, Object>
    return this.parseEntry(expense || json)
  }

  async deleteExpense(id: string): Promise<void> {
    await this.request(http.RequestMethod.DELETE, `/expenses/${id}`)
  }

  private parseEntry(json: Record<string, Object>): ExpenseEntry {
    const tagsRaw = json['tags'] as string || ''
    const tags = tagsRaw.length > 0 ? tagsRaw.split(',') : []
    return new ExpenseEntry(
      String(json['id'] || ''),
      Number(json['amount'] || 0),
      String(json['notes'] || ''),
      tags,
      String(json['currency'] || 'CAD'),
      String(json['date'] || ''),
      String(json['created_at'] || json['createdAt'] || '')
    )
  }

  private parseStats(json: Record<string, Object>): ExpenseStats {
    const tagTotalsRaw = json['tag_totals'] as Object[] || []
    const tagTotals: TagTotal[] = []
    for (const t of tagTotalsRaw) {
      const item = t as Record<string, Object>
      tagTotals.push(new TagTotal(
        String(item['tag'] || ''),
        Number(item['amount'] || 0),
        Number(item['count'] || 0)
      ))
    }

    const categoryTotalsRaw = json['category_totals'] as Object[] || []
    const categoryTotals: CategoryTotal[] = []
    for (const c of categoryTotalsRaw) {
      const item = c as Record<string, Object>
      categoryTotals.push(new CategoryTotal(
        String(item['category'] || ''),
        Number(item['amount'] || 0),
        Number(item['count'] || 0),
        Number(item['percentage'] || 0)
      ))
    }

    const dailyRaw = json['daily'] as Object[] || []
    const daily: DailyAmount[] = []
    for (const d of dailyRaw) {
      const item = d as Record<string, Object>
      daily.push(new DailyAmount(
        String(item['date'] || ''),
        Number(item['amount'] || 0)
      ))
    }

    let comparison: Comparison | null = null
    const compRaw = json['comparison'] as Record<string, Object>
    if (compRaw) {
      comparison = new Comparison(
        Number(compRaw['prev_total'] || 0),
        Number(compRaw['change_percent'] || 0)
      )
    }

    return new ExpenseStats(
      String(json['period'] || ''),
      String(json['from'] || ''),
      String(json['to'] || ''),
      Number(json['total_amount'] || 0),
      Number(json['entry_count'] || 0),
      tagTotals,
      categoryTotals,
      daily,
      comparison
    )
  }
}

export const NextApiClient = new NextApiClientClass()
