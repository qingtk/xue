---
layout: post
title:  "sagecell example"
tags: sagecell
math: on
contributors: "Cody Luo"
---

# SageCell示例

## 简单计算

<div class="sage"><script type="text/x-sage">
print("Hello from SageCell!")

# 三角函数图像
plot(sin(x), (x, 0, 2*pi))
</script></div>

## 交互式计算

```sage
@interact
def _(a=(1, 10)):
    print(factorial(a))
```