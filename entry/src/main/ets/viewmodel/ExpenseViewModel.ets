import { NextApiClient } from '../service/NextApiClient'
import { ExpenseEntry, ExpenseStats, CreateExpenseParams } from '../model/ExpenseModels'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'

const TAG = Constants.TAG_EXPENSE

@Observed
export class ExpenseViewModel {
  entries: ExpenseEntry[] = []
  filteredEntries: ExpenseEntry[] = []
  stats: ExpenseStats | null = null
  selectedTag: string = ''
  period: string = 'month'
  currentYear: number = new Date().getFullYear()
  currentMonth: number = new Date().getMonth() + 1
  isLoading: boolean = false
  errorMessage: string = ''

  async init(): Promise<void> {
    await this.loadData()
  }

  async loadData(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    const monthStr = `${this.currentYear}-${String(this.currentMonth).padStart(2, '0')}`
    const dateStr = `${monthStr}-01`

    try {
      this.stats = await NextApiClient.getExpenseStats(this.period, dateStr)
      this.entries = await NextApiClient.getExpenses(monthStr)
      this.applyFilter()
      Logger.info(TAG, `数据加载完成 entries=${this.entries.length}`)
    } catch (err) {
      this.errorMessage = (err as Error).message || '加载失败'
      Logger.error(TAG, `数据加载失败 error=${this.errorMessage}`)
    } finally {
      this.isLoading = false
    }
  }

  switchPeriod(period: string): void {
    this.period = period
    this.loadData()
  }

  switchMonth(delta: number): void {
    this.currentMonth += delta
    if (this.currentMonth > 12) {
      this.currentMonth = 1
      this.currentYear += 1
    } else if (this.currentMonth < 1) {
      this.currentMonth = 12
      this.currentYear -= 1
    }
    this.selectedTag = ''
    this.loadData()
  }

  filterByTag(tag: string): void {
    this.selectedTag = tag
    this.applyFilter()
  }

  private applyFilter(): void {
    if (this.selectedTag.length === 0) {
      this.filteredEntries = this.entries.slice()
    } else {
      this.filteredEntries = this.entries.filter(e => e.tags.indexOf(this.selectedTag) >= 0)
    }
  }

  async createExpense(amount: number, notes: string, tags: string, currency: string, date: string): Promise<boolean> {
    try {
      const params = new CreateExpenseParams(amount, notes, tags, currency, date)
      await NextApiClient.createExpense(params)
      await this.loadData()
      return true
    } catch (err) {
      this.errorMessage = (err as Error).message || '记账失败'
      return false
    }
  }

  async deleteExpense(id: string): Promise<boolean> {
    try {
      await NextApiClient.deleteExpense(id)
      await this.loadData()
      return true
    } catch (err) {
      this.errorMessage = (err as Error).message || '删除失败'
      return false
    }
  }

  getMonthLabel(): string {
    return `${this.currentYear}年${this.currentMonth}月`
  }

  getGroupedEntries(): Map<string, ExpenseEntry[]> {
    const groups = new Map<string, ExpenseEntry[]>()
    for (const entry of this.filteredEntries) {
      const dateKey = entry.date
      const existing = groups.get(dateKey)
      if (existing) {
        existing.push(entry)
      } else {
        groups.set(dateKey, [entry])
      }
    }
    return groups
  }

  getDayTotal(entries: ExpenseEntry[]): number {
    let total = 0
    for (const e of entries) {
      total += e.amount
    }
    return total
  }
}
