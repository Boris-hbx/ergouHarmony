// 记账条目
export class ExpenseEntry {
  id: string
  amount: number
  notes: string
  tags: string[]
  currency: string
  date: string
  createdAt: string

  constructor(
    id: string,
    amount: number,
    notes: string,
    tags: string[],
    currency: string,
    date: string,
    createdAt: string
  ) {
    this.id = id
    this.amount = amount
    this.notes = notes
    this.tags = tags
    this.currency = currency
    this.date = date
    this.createdAt = createdAt
  }
}

// 创建记账参数
export class CreateExpenseParams {
  amount: number
  notes: string
  tags: string
  currency: string
  date: string

  constructor(amount: number, notes: string, tags: string, currency: string, date: string) {
    this.amount = amount
    this.notes = notes
    this.tags = tags
    this.currency = currency
    this.date = date
  }
}

// 标签统计
export class TagTotal {
  tag: string
  amount: number
  count: number

  constructor(tag: string, amount: number, count: number) {
    this.tag = tag
    this.amount = amount
    this.count = count
  }
}

// 分类统计
export class CategoryTotal {
  category: string
  amount: number
  count: number
  percentage: number

  constructor(category: string, amount: number, count: number, percentage: number) {
    this.category = category
    this.amount = amount
    this.count = count
    this.percentage = percentage
  }
}

// 每日金额
export class DailyAmount {
  date: string
  amount: number

  constructor(date: string, amount: number) {
    this.date = date
    this.amount = amount
  }
}

// 环比对比
export class Comparison {
  prevTotal: number
  changePercent: number

  constructor(prevTotal: number, changePercent: number) {
    this.prevTotal = prevTotal
    this.changePercent = changePercent
  }
}

// 统计数据
export class ExpenseStats {
  period: string
  from: string
  to: string
  totalAmount: number
  entryCount: number
  tagTotals: TagTotal[]
  categoryTotals: CategoryTotal[]
  daily: DailyAmount[]
  comparison: Comparison | null

  constructor(
    period: string,
    from: string,
    to: string,
    totalAmount: number,
    entryCount: number,
    tagTotals: TagTotal[],
    categoryTotals: CategoryTotal[],
    daily: DailyAmount[],
    comparison: Comparison | null
  ) {
    this.period = period
    this.from = from
    this.to = to
    this.totalAmount = totalAmount
    this.entryCount = entryCount
    this.tagTotals = tagTotals
    this.categoryTotals = categoryTotals
    this.daily = daily
    this.comparison = comparison
  }
}
