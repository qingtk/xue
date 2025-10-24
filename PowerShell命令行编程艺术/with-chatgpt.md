# PowerShell 命令行编程艺术

> 本文档面向想把 PowerShell 当作生产力工具与脚本平台的读者。内容从基础到高级、并包含大量实用技巧与注意事项，既适合新手快速上手，也对有经验的工程师提供进阶参考。

---

## 目录

1. 简介
2. 快速开始（基础概念）
3. 常用命令与模式
4. 管道与对象思维
5. 脚本、模块与包管理
6. 高级功能（远程、作业、并行、事件）
7. 调试、测试与日志
8. 性能优化与最佳实践
9. 安全与权限注意事项
10. 常见陷阱与防范
11. 实用一行命令与技巧集合
12. 参考资料与延伸阅读

---

## 1. 简介

PowerShell 是 Microsoft 设计的跨平台命令行壳与脚本语言，基于 .NET（Core / 5+）。与传统的文本流 shell（如 Bash）不同，PowerShell 传递的是 **对象**，这改变了构建脚本和处理数据的思路。

* 主要版本：Windows PowerShell（基于 Full .NET，Windows 特有）与 PowerShell (Core)（跨平台，基于 .NET Core/.NET）。
* 可运行环境：Windows、Linux、macOS。

目标：掌握 PowerShell 的核心概念，写出可维护、健壮与高效的脚本。

---

## 2. 快速开始（基础概念）

### 2.1 命令和别名

PowerShell 的命令称为 cmdlet，常见格式 `Verb-Noun`（例如 `Get-Process`, `Set-Item`）。Windows 上内置了大量别名（如 `ls`、`dir`、`cat`）。

示例：

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

### 2.2 变量与类型

变量以 `$` 开头，PowerShell 是强类型但类型推断友好：

```powershell
$a = 1           # 整数
$b = "hello"    # 字符串
$array = 1,2,3    # 数组
$hashtable = @{k='v'}

[int]$n = 5       # 显式类型声明
```

### 2.3 数组与哈希表

* 使用逗号创建数组：`$arr = 1,2,3`
* 使用 `@()` 强制数组：`$arr = @()`
* 哈希表：`$h = @{Name='ahmeng'; Age=27}`

### 2.4 流控制

`if/else`, `switch`, `for`, `foreach`, `while`, `do { } while` 均可使用。注意 `foreach` 有关键字版与方法版（`.ForEach()`）。

---

## 3. 常用命令与模式

### 3.1 文件操作

```powershell
Get-ChildItem -Path . -Recurse -File | Where-Object { $_.Length -gt 1MB }
Get-Content file.txt -Tail 50            # 类似 tail
Set-Content out.txt "hello"            # 覆盖写入
Add-Content out.txt "append"           # 追加
```

### 3.2 进程与服务

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 }
Stop-Process -Name notepad
Get-Service | Where-Object Status -eq 'Running'
```

### 3.3 注册表（Windows）

PowerShell 可像操作文件一样访问注册表：`Get-ItemProperty HKLM:\Software\...`。

---

## 4. 管道与对象思维

PowerShell 的核心优势在于：**传递对象，而非文本**。

```powershell
Get-Process | Where-Object {$_.CPU -gt 100} | Select-Object Name, Id, CPU
```

* `Where-Object` 与 `Select-Object` 操作的是对象属性。
* 使用 `Format-Table` / `Format-List` 仅用于最终展示，不应在脚本中传给后续处理（会把对象转换成格式化输出）。

### 4.1 常用管道技巧

* 使用 `Select-Object -Property *` 查看对象所有属性。
* 使用 `ForEach-Object` 进行逐项操作：

```powershell
Get-ChildItem | ForEach-Object { $_.FullName.Length }
```

* 使用 `Where` 的脚本块简写：`Where-Object { $_.Length -gt 1MB }` 或 PowerShell 7+ 的简写 `Where Length -gt 1MB`。

---

## 5. 脚本、模块与包管理

### 5.1 脚本结构

* 文件名建议以 `.ps1` 结尾。
* 添加头部注释说明作者、功能、示例和参数。

示例脚本头：

```powershell
<#
.SYNOPSIS
    将 CSV 导入并按列汇总
.PARAMETER Path
    CSV 文件路径
.EXAMPLE
    .\my.ps1 -Path data.csv
#>
param([string]$Path)
```

### 5.2 参数与参数验证

使用 `param()` 或 `[CmdletBinding()]` 来声明参数与参数集：

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath,

    [ValidateSet('csv','json')]
    [string]$Format = 'csv'
)
```

### 5.3 模块化

创建模块（`.psm1`）并导出函数或使用 `ModuleManifest`（`.psd1`）。遵循单一职责，把常用函数放进模块便于重用。

### 5.4 包管理

使用 PowerShell Gallery：`Publish-Module` / `Find-Module` / `Install-Module`。

---

## 6. 高级功能（远程、作业、并行、事件）

### 6.1 远程（Remoting）

* 使用 `Enter-PSSession`（交互）或 `Invoke-Command`（批量/脚本）对远端主机执行命令。
* Windows：WinRM（需要配置）。跨平台 PowerShell Core 支持 SSH 为传输协议。

示例：

```powershell
Invoke-Command -ComputerName server01 -ScriptBlock { Get-Process }
```

### 6.2 后台作业与管道并行（PowerShell 7+）

* `Start-Job`/`Get-Job`/`Receive-Job` 管理后台作业。
* PowerShell 7+ 的 `ForEach-Object -Parallel` 提供简单并行处理。

```powershell
1..10 | ForEach-Object -Parallel { Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 3); $_ }
```

### 6.3 事件驱动与订阅

使用 `Register-ObjectEvent` 订阅系统事件或自定义事件，适合长期运行的脚本/守护进程。

### 6.4 C# 类与面向对象

PowerShell 支持定义类（PSv5+）：

```powershell
class Person {
    [string]$Name
    Person([string]$name){ $this.Name = $name }
    [string] ToString(){ return "Person: $($this.Name)" }
}
$p = [Person]::new('ahmeng')
```

---

## 7. 调试、测试与日志

### 7.1 调试

* 使用 `Set-PSBreakpoint`、`Get-PSCallStack` 或在 VS Code 中使用 PowerShell 扩展进行断点调试。
* `Write-Debug`, `Write-Verbose`, `Write-Error`, `Write-Warning` 用于不同级别的日志输出，结合 `$VerbosePreference` 等开关。

示例：

```powershell
Write-Verbose "正在处理 $Path" -Verbose
```

### 7.2 单元测试

使用 Pester（PowerShell 的测试框架）：

```powershell
Describe 'MyFunction' {
  It 'returns expected value' {
    MyFunction 1 | Should -Be 2
  }
}
```

### 7.3 日志记录

* 生产脚本建议把关键操作写到文件或事件日志。
* 使用 `Start-Transcript` 捕获会话（注意敏感信息）。

---

## 8. 性能优化与最佳实践

### 8.1 避免不必要的子进程

尽量使用原生 cmdlet 而非调用外部可执行文件，避免频繁启动外部程序。

### 8.2 使用过滤器尽早过滤

把 `Where-Object` 的过滤放在管道前端，减少数据量传输与处理成本。

### 8.3 批量操作而非逐项开销

利用 `Get-ChildItem -Recurse` + `Where-Object` 一次性筛选，而不是在循环里多次读取磁盘。

### 8.4 避免 `Format-*` 在中间步骤

`Format-Table` 等会把对象转成格式化输出，破坏后续处理。

---

## 9. 安全与权限注意事项

* 默认执行策略（ExecutionPolicy）会影响脚本运行：`Restricted`, `RemoteSigned`, `Unrestricted` 等。建议在受控环境下使用 `RemoteSigned` 或 `AllSigned`。
* 避免在脚本中硬编码凭据，使用 `Get-Credential`、凭据保管库（例如 Windows Credential Manager 或 Key Vault）或使用安全字符串 `ConvertTo-SecureString`。
* 在处理外部输入时做好校验（例如文件路径、用户名等），防止注入或路径穿越。
* 对远程执行启用与限制访问，仅在可信网络与受控身份验证下使用 Remoting。

示例：使用安全方式保存凭据：

```powershell
$cred = Get-Credential            # 交互式读取
# 或: 从加密文件读取（仅限当前用户/机器）
$secure = ConvertTo-SecureString "plaintext" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('user',$secure)
```

---

## 10. 常见陷阱与防范

* **陷阱：** 把 `Format-*` 的结果传给文件或再次处理。

  * **防范：** 只在最终输出时格式化。

* **陷阱：** 假设管道一定保留元素顺序。

  * **防范：** 如果顺序重要，显式排序 `Sort-Object`。

* **陷阱：** 忽视错误处理（$ErrorActionPreference）和命令失败的可能。

  * **防范：** 使用 `-ErrorAction Stop` 并结合 `try/catch`。

示例：

```powershell
try{
  Copy-Item $src $dest -ErrorAction Stop
} catch {
  Write-Error "复制失败: $_"
}
```

---

## 11. 实用一行命令与技巧集合

* 查找大文件：

```powershell
Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.Length -gt 100MB }
```

* 批量重命名：

```powershell
Get-ChildItem *.txt | Rename-Item -NewName { $_.Name -replace 'old','new' }
```

* 将 CSV 转为 JSON：

```powershell
Import-Csv data.csv | ConvertTo-Json | Set-Content data.json
```

* 监控文件变化并触发脚本（简单示例）：

```powershell
$fsw = New-Object IO.FileSystemWatcher '.' -Property @{ IncludeSubdirectories = $true; Filter='*.log' }
Register-ObjectEvent $fsw Changed -Action { Write-Output "文件变化: $($Event.SourceEventArgs.FullPath)" }
```

---

## 12. 参考资料与延伸阅读

* PowerShell 官方文档（Microsoft Docs）
* PowerShell Gallery
* Pester 测试框架
* 书籍：*Windows PowerShell in Action*, *Learn PowerShell in a Month of Lunches*

---

### 附：推荐的编辑器与插件

* Visual Studio Code + PowerShell 扩展（调试、语法高亮、IntelliSense）
* PowerShell ISE（Windows，老牌）

---

如果你想，我可以：

* 把本文导出为 `.md` 或 `.pdf` 文件并提供下载。
* 根据你的工作场景（系统管理／DevOps／数据处理）生成专门的最佳实践与脚本模板。

欢迎告诉我你想优先补充或扩展的章节！
