import { http } from '@kit.NetworkKit'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { ChatRequest, ChatResponseChunk, ToolCall } from '../model/LLMModels'

const TAG = Constants.TAG_LLM

// 流式回调
export interface StreamCallback {
  onContent(content: string): void
  onToolCalls(toolCalls: ToolCall[]): void
  onDone(finishReason: string): void
  onError(error: string): void
}

export class LLMClient {
  private httpRequest: http.HttpRequest | null = null
  private sseBuffer: string = ''

  async chatStream(request: ChatRequest, callback: StreamCallback): Promise<void> {
    this.sseBuffer = ''
    this.httpRequest = http.createHttp()
    const toolCallsAccumulator: Map<number, ToolCall> = new Map()

    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      const text = this.arrayBufferToString(data)
      this.sseBuffer += text
      this.processSSEBuffer(callback, toolCallsAccumulator)
    })

    this.httpRequest.on('dataEnd', () => {
      // 处理缓冲区残留
      if (this.sseBuffer.trim().length > 0) {
        this.processSSEBuffer(callback, toolCallsAccumulator)
      }
      // 如果积累了 tool_calls，在结束时一次性回调
      if (toolCallsAccumulator.size > 0) {
        const toolCalls: ToolCall[] = []
        toolCallsAccumulator.forEach((tc) => toolCalls.push(tc))
        callback.onToolCalls(toolCalls)
      }
      this.cleanup()
    })

    try {
      const response = await this.httpRequest.requestInStream(Constants.DEEPSEEK_API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Constants.DEEPSEEK_API_KEY}`,
          'Accept': 'text/event-stream'
        },
        extraData: JSON.stringify(request),
        expectDataType: http.HttpDataType.STRING
      })

      if (response.responseCode !== 200) {
        callback.onError(`HTTP ${response.responseCode}`)
        this.cleanup()
      }
    } catch (err) {
      Logger.error(TAG, `请求失败 error=${JSON.stringify(err)}`)
      callback.onError((err as Error).message || '网络请求失败')
      this.cleanup()
    }
  }

  abort(): void {
    if (this.httpRequest) {
      try {
        this.httpRequest.destroy()
      } catch {
        // 忽略
      }
      this.httpRequest = null
    }
  }

  private processSSEBuffer(callback: StreamCallback, toolCallsAccumulator: Map<number, ToolCall>): void {
    const lines = this.sseBuffer.split('\n')
    // 保留最后一行（可能不完整）
    this.sseBuffer = lines[lines.length - 1]

    for (let i = 0; i < lines.length - 1; i++) {
      const line = lines[i].trim()
      if (!line.startsWith('data: ')) {
        continue
      }
      const jsonStr = line.substring(6)
      if (jsonStr === '[DONE]') {
        callback.onDone('stop')
        return
      }
      try {
        const chunk = JSON.parse(jsonStr) as ChatResponseChunk
        if (!chunk.choices || chunk.choices.length === 0) {
          continue
        }
        const choice = chunk.choices[0]
        const delta = choice.delta

        // 文本内容
        if (delta.content) {
          callback.onContent(delta.content)
        }

        // 工具调用（流式积累）
        if (delta.tool_calls) {
          for (const tc of delta.tool_calls) {
            const idx = tc.index ?? 0
            const existing = toolCallsAccumulator.get(idx)
            if (existing) {
              // 追加 arguments
              if (tc.function?.arguments) {
                existing.function.arguments += tc.function.arguments
              }
            } else {
              toolCallsAccumulator.set(idx, {
                id: tc.id || '',
                type: 'function',
                function: {
                  name: tc.function?.name || '',
                  arguments: tc.function?.arguments || ''
                }
              })
            }
          }
        }

        // 完成原因
        if (choice.finish_reason) {
          if (choice.finish_reason === 'tool_calls') {
            // 触发工具调用回调
            if (toolCallsAccumulator.size > 0) {
              const toolCalls: ToolCall[] = []
              toolCallsAccumulator.forEach((tc) => toolCalls.push(tc))
              toolCallsAccumulator.clear()
              callback.onToolCalls(toolCalls)
            }
          }
          callback.onDone(choice.finish_reason)
        }
      } catch {
        // JSON 解析失败跳过
      }
    }
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    let result = ''
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i])
    }
    // 处理 UTF-8 多字节字符
    try {
      return decodeURIComponent(escape(result))
    } catch {
      return result
    }
  }

  private cleanup(): void {
    this.sseBuffer = ''
    if (this.httpRequest) {
      try {
        this.httpRequest.off('dataReceive')
        this.httpRequest.off('dataEnd')
        this.httpRequest.destroy()
      } catch {
        // 忽略
      }
      this.httpRequest = null
    }
  }
}
