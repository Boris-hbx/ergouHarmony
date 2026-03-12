import { Tool } from '../model/ToolModels'

export class SimpleCalculateTool implements Tool {
  name: string = 'simple_calculate'
  description: string = '简单数学计算'
  parametersSchema: string = '{"type":"object","properties":{"expression":{"type":"string","description":"数学表达式，如 \\"100 * 1.13\\""}},"required":["expression"]}'

  async execute(args: Record<string, Object>): Promise<string> {
    const expression = args['expression'] as string
    if (!expression) {
      return '{"error":"缺少 expression 参数"}'
    }

    // 安全校验：只允许数字、运算符、括号、小数点、空格
    if (!/^[\d\s+\-*/().%]+$/.test(expression)) {
      return '{"error":"不支持的表达式"}'
    }

    try {
      const result = this.evaluate(expression)
      return `{"expression":"${expression}","result":${result}}`
    } catch (e) {
      return '{"error":"计算失败，请检查表达式"}'
    }
  }

  // 递归下降解析器，支持 +, -, *, /, (), 小数
  private evaluate(expr: string): number {
    const parser = new ExprParser(expr)
    const result = parser.parseExpression()
    if (parser.pos < parser.tokens.length) {
      throw new Error('unexpected token')
    }
    return result
  }
}

// 简单 token 类型
class Token {
  type: string // 'number' | 'op' | 'lparen' | 'rparen'
  value: string

  constructor(type: string, value: string) {
    this.type = type
    this.value = value
  }
}

class ExprParser {
  tokens: Token[] = []
  pos: number = 0

  constructor(expr: string) {
    this.tokens = this.tokenize(expr)
  }

  private tokenize(expr: string): Token[] {
    const result: Token[] = []
    let i = 0
    while (i < expr.length) {
      const ch = expr.charAt(i)
      if (ch === ' ') {
        i++
        continue
      }
      if (ch === '(') {
        result.push(new Token('lparen', '('))
        i++
      } else if (ch === ')') {
        result.push(new Token('rparen', ')'))
        i++
      } else if (ch === '+' || ch === '-' || ch === '*' || ch === '/' || ch === '%') {
        result.push(new Token('op', ch))
        i++
      } else if ((ch >= '0' && ch <= '9') || ch === '.') {
        let num = ''
        while (i < expr.length && ((expr.charAt(i) >= '0' && expr.charAt(i) <= '9') || expr.charAt(i) === '.')) {
          num += expr.charAt(i)
          i++
        }
        result.push(new Token('number', num))
      } else {
        throw new Error(`unexpected char: ${ch}`)
      }
    }
    return result
  }

  private peek(): Token | null {
    if (this.pos < this.tokens.length) {
      return this.tokens[this.pos]
    }
    return null
  }

  private consume(): Token {
    const t = this.tokens[this.pos]
    this.pos++
    return t
  }

  // expression = term (('+' | '-') term)*
  parseExpression(): number {
    let left = this.parseTerm()
    let t = this.peek()
    while (t !== null && t.type === 'op' && (t.value === '+' || t.value === '-')) {
      const op = this.consume().value
      const right = this.parseTerm()
      if (op === '+') {
        left = left + right
      } else {
        left = left - right
      }
      t = this.peek()
    }
    return left
  }

  // term = unary (('*' | '/' | '%') unary)*
  private parseTerm(): number {
    let left = this.parseUnary()
    let t = this.peek()
    while (t !== null && t.type === 'op' && (t.value === '*' || t.value === '/' || t.value === '%')) {
      const op = this.consume().value
      const right = this.parseUnary()
      if (op === '*') {
        left = left * right
      } else if (op === '/') {
        left = left / right
      } else {
        left = left % right
      }
      t = this.peek()
    }
    return left
  }

  // unary = ('-' | '+')? primary
  private parseUnary(): number {
    const t = this.peek()
    if (t !== null && t.type === 'op' && (t.value === '-' || t.value === '+')) {
      const op = this.consume().value
      const val = this.parsePrimary()
      if (op === '-') {
        return -val
      }
      return val
    }
    return this.parsePrimary()
  }

  // primary = number | '(' expression ')'
  private parsePrimary(): number {
    const t = this.peek()
    if (t === null) {
      throw new Error('unexpected end of expression')
    }
    if (t.type === 'number') {
      this.consume()
      return parseFloat(t.value)
    }
    if (t.type === 'lparen') {
      this.consume() // consume '('
      const val = this.parseExpression()
      const closing = this.peek()
      if (closing === null || closing.type !== 'rparen') {
        throw new Error('missing closing parenthesis')
      }
      this.consume() // consume ')'
      return val
    }
    throw new Error(`unexpected token: ${t.value}`)
  }
}
