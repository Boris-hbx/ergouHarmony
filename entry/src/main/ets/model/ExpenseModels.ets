// 记账条目
export interface ExpenseEntry {
  id: string
  amount: number
  notes: string
  tags: string[]
  currency: 'CAD' | 'CNY' | 'USD'
  date: string
  createdAt: string
}

// 记账摘要
export interface ExpenseSummary {
  totalAmount: number
  count: number
  currency: string
  period: string
  comparison?: string
}
