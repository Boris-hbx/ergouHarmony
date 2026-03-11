import { http } from '@kit.NetworkKit'
import { Logger } from '../common/Logger'
import { Constants } from '../common/Constants'
import { ChatRequest } from '../model/LLMModels'

const TAG = Constants.TAG_LLM

// 工具调用信息
export interface ToolCallInfo {
  id: string
  name: string
  inputJson: string
}

// 流式回调
export interface StreamCallback {
  onContent(content: string): void
  onToolUse(toolCalls: ToolCallInfo[]): void
  onDone(stopReason: string): void
  onError(error: string): void
}

export class LLMClient {
  private httpRequest: http.HttpRequest | null = null
  private sseBuffer: string = ''

  async chatStream(request: ChatRequest, callback: StreamCallback): Promise<void> {
    this.sseBuffer = ''
    this.httpRequest = http.createHttp()

    // 积累工具调用
    const pendingToolCalls: ToolCallInfo[] = []
    let currentToolId = ''
    let currentToolName = ''
    let currentToolInput = ''
    let stopReason = ''

    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      const text = this.arrayBufferToString(data)
      this.sseBuffer += text

      // 按行解析 SSE
      const lines = this.sseBuffer.split('\n')
      this.sseBuffer = lines[lines.length - 1]

      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim()

        if (line.startsWith('data: ')) {
          const jsonStr = line.substring(6)
          try {
            const event = JSON.parse(jsonStr) as Record<string, Object>
            const eventType = event['type'] as string

            if (eventType === 'content_block_start') {
              const block = event['content_block'] as Record<string, Object>
              if (block['type'] === 'tool_use') {
                currentToolId = block['id'] as string || ''
                currentToolName = block['name'] as string || ''
                currentToolInput = ''
              }
            } else if (eventType === 'content_block_delta') {
              const delta = event['delta'] as Record<string, Object>
              const deltaType = delta['type'] as string

              if (deltaType === 'text_delta') {
                const text = delta['text'] as string
                if (text) {
                  callback.onContent(text)
                }
              } else if (deltaType === 'input_json_delta') {
                const partialJson = delta['partial_json'] as string
                if (partialJson) {
                  currentToolInput += partialJson
                }
              }
            } else if (eventType === 'content_block_stop') {
              // 如果是工具块结束，收集
              if (currentToolId.length > 0) {
                pendingToolCalls.push({
                  id: currentToolId,
                  name: currentToolName,
                  inputJson: currentToolInput || '{}'
                })
                currentToolId = ''
                currentToolName = ''
                currentToolInput = ''
              }
            } else if (eventType === 'message_delta') {
              const delta = event['delta'] as Record<string, Object>
              stopReason = delta['stop_reason'] as string || 'end_turn'
            } else if (eventType === 'message_stop') {
              // 消息结束
              if (pendingToolCalls.length > 0) {
                callback.onToolUse(pendingToolCalls)
              }
              callback.onDone(stopReason || 'end_turn')
            } else if (eventType === 'error') {
              const error = event['error'] as Record<string, Object>
              callback.onError(error['message'] as string || '未知错误')
            }
          } catch {
            // JSON 解析失败跳过
          }
        }
      }
    })

    this.httpRequest.on('dataEnd', () => {
      this.cleanup()
    })

    try {
      const response = await this.httpRequest.requestInStream(Constants.CLAUDE_API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'x-api-key': Constants.CLAUDE_API_KEY,
          'anthropic-version': Constants.CLAUDE_API_VERSION
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

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    let result = ''
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i])
    }
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
