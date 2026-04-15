import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String
    var foregroundColor: Color = .primary
    
    var body: some View {
        Markdown(content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(foregroundColor)
    }
}

#Preview {
    MarkdownText(content: """
# 标题 1
## 标题 2
### 标题 3

**粗体文本** 和 *斜体文本*

行内 `代码` 示例

```swift
func hello() {
    print("Hello, Markdown!")
}
```

- 无序列表项 1
- 无序列表项 2
  - 嵌套列表项

1. 有序列表项 1
2. 有序列表项 2

[链接文本](https://example.com)

> 引用块
> 第二行引用
""")
}
