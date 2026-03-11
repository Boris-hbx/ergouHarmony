export class PromptSanitizer {
  // 危险的 prompt 注入模式
  private static readonly INJECTION_PATTERNS: RegExp[] = [
    /ignore\s+(all\s+)?(previous|above|prior)\s+(instructions|prompts)/i,
    /you\s+are\s+now\s+(a|an)\s+/i,
    /system\s*:\s*/i,
    /\[INST\]/i,
    /<<\s*SYS\s*>>/i,
    /\{\{.*\}\}/,
  ]

  static sanitize(input: string): string {
    let sanitized = input.trim()

    // 移除零宽字符
    sanitized = sanitized.replace(/[\u200B-\u200D\uFEFF]/g, '')

    // 检测并标记潜在注入
    for (const pattern of PromptSanitizer.INJECTION_PATTERNS) {
      if (pattern.test(sanitized)) {
        sanitized = sanitized.replace(pattern, '[FILTERED]')
      }
    }

    return sanitized
  }

  static isClean(input: string): boolean {
    return PromptSanitizer.INJECTION_PATTERNS.every(p => !p.test(input))
  }
}
