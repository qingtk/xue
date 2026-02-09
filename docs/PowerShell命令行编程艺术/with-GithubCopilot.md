# PowerShell命令行编程艺术（GitHub Copilot版）

本指南面向想用 PowerShell 做日常自动化、系统管理、开发辅助以及脚本编写的读者。内容从基础到高级，并包含实用技巧、常见陷阱与最佳实践示例。文中示例以 PowerShell 7+（跨平台）为主，同时兼顾 Windows PowerShell（5.1）差异提示。

## 兼容性注记

- 本文默认以 PowerShell 7+（Core）为准。Windows PowerShell 5.1 与 7+ 在一些命令参数、编码默认值与并行处理特性上存在差异，例如 `ForEach-Object -Parallel` 仅在 PowerShell 7+ 可用；PowerShell Core 的默认编码为 UTF-8，而 5.1 仍使用 UTF-16/ANSI（取决于上下文）。在撰写脚本时，请标注目标 PowerShell 版本或使用兼容性检查。 
___

## PowerShell 基础

### 交互式使用

PowerShell 是基于对象的命令行外壳。与传统的文本流不同，PowerShell 在管道中传递 .NET 对象。

示例：列出当前目录并按大小排序：

```powershell
Get-ChildItem -File | Sort-Object Length -Descending | Select-Object -First 10
```

要快速查看某一命令的参数与帮助：

```powershell
Get-Help Get-ChildItem -Full
```

如果帮助未安装，先运行：

```powershell
Update-Help -Force
```

### 对象管道与管道传输

管道中传递的是对象，不是文本，这允许直接访问属性：

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 } | Select-Object Name, Id, CPU
```

使用 Select-Object、Select-String、Format-Table 等工具在不同场景下选择和格式化输出。

### 常用命令与别名

- ls / dir -> Get-ChildItem
- cat -> Get-Content
- ps -> Get-Process
- rm -> Remove-Item

使用 Get-Command -Module <模块名> 查看模块命令。

### 变量、类型与强制转换

变量以 $ 开头：$name = 'xue'

强制类型转换示例：

```powershell
[int]$n = "42"
```

注意：自动类型推断有时会导致数组或单个元素的差异，使用 , 运算符保证数组：

```powershell
$a = ,(Get-ChildItem | Where-Object { $_.PSIsContainer })
```

## 高级功能与脚本化

### 模块与函数设计

- 编写模块（*.psm1）来封装函数。
- 使用 Export-ModuleMember 指定导出函数。

示例函数模板：

```powershell
function Get-MyData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        [switch]$Recurse
    )

    process {
        Get-ChildItem -Path $Path -File -Recurse:$Recurse
    }
}
```

### 参数绑定与参数集

使用 Parameter 属性控制参数绑定、位置、别名与参数集。参数集允许在同一函数中定义互斥的参数组合。

### 异常处理与调试

- 使用 try/catch/finally 捕获异常。
- 使用 -ErrorAction Stop 将非终止错误提升为异常。
- 使用 Write-Debug / Write-Verbose 提供可选诊断输出。

示例：

```powershell
try {
    Get-Content missing.file -ErrorAction Stop
} catch {
  # 捕获时 $_ 是 ErrorRecord，优先尝试输出异常信息
  Write-Warning "读取文件失败: $($_.Exception.Message)"
} finally {
    Write-Verbose "清理完成"
}
```

### 异步/并行：Jobs、Runspaces、ForEach-Object -Parallel

- Start-Job / Receive-Job：适用于后台任务，但与当前会话对象不可直接共享。
- ForEach-Object -Parallel（PowerShell 7+）提供内置并行处理。

示例并行处理（PowerShell 7+）：

```powershell
$items = 1..10
$items | ForEach-Object -Parallel {
  # 并行代码块：管道当前项可通过 $_ 访问；若要在并行脚本块中使用外部变量，请使用 $using: 前缀
  Write-Output "处理: $_ (运行在 $env:COMPUTERNAME)"
} -ThrottleLimit 4
```

注意：并行脚本块在独立的子进程中执行，管道项通过 $_ 可用；若需引用函数外部的变量或对象，请使用 $using:VarName 前缀。此外，可通过 -ThrottleLimit 控制并行度。

## 系统与文件操作

### 文件、目录、权限管理

- Get-Acl / Set-Acl 管理 NTFS 权限。
- 使用 Test-Path 检查存在性。
- 推荐使用 Join-Path 构造路径以跨平台兼容。

示例：安全地创建目录：

```powershell
$dir = Join-Path $env:USERPROFILE 'mydata'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir }
```

### 注册表与服务控制

- 使用 Get-ItemProperty / Set-ItemProperty 操作注册表（Windows）。
- 使用 Get-Service / Start-Service / Stop-Service 管理服务。

### 进程与性能监控

- Get-Process、Stop-Process、Measure-Command（测量执行时间）。

示例测量命令耗时：

```powershell
Measure-Command { Get-ChildItem -Recurse | Out-Null }
```

## 网络与 HTTP 自动化

### Invoke-WebRequest / Invoke-RestMethod

- Invoke-RestMethod 会自动将 JSON 转换为对象，适合 API 使用。

示例 GET 请求：

```powershell
$resp = Invoke-RestMethod -Uri 'https://api.github.com/repos/qingtk/xue' -Headers @{ 'User-Agent' = 'PowerShell' }
$resp.full_name
```

示例 POST JSON（推荐在脚本中使用 SecretManagement 存储令牌，或从环境变量读取）：

```powershell
$body = @{ title = '自动化 Issue'; body = '由 PowerShell 创建' } | ConvertTo-Json
Invoke-RestMethod -Uri 'https://api.github.com/repos/<owner>/<repo>/issues' -Method Post -Body $body -ContentType 'application/json' -Headers @{ Authorization = "Bearer $token"; 'User-Agent' = 'PowerShell'; 'Accept' = 'application/vnd.github+json' }
```

注意处理速率限制与身份验证。示例脚本见 `./scripts/create-github-issue.ps1`，建议结合 Microsoft.PowerShell.SecretManagement 存储与读取 GitHub 令牌。

## 与 Git / GitHub 的集成

- 直接在脚本中调用 git（CLI）来提交、推送。
- 使用 GitHub REST API 或 GraphQL 进行自动化任务（需要令牌）。

示例获取当前分支名：

```powershell
(git rev-parse --abbrev-ref HEAD).Trim()
```

示例脚本：`./scripts/create-github-issue.ps1`（演示如何结合 SecretManagement 创建 Issue）。

## PowerShell 实用技巧

### 交互友好输出

- 使用 Out-GridView (Windows) 进行图形化快速选择。
- 使用 Format-Table -AutoSize 或 Format-List 以更好的控制显示。

### 读写 JSON、YAML、CSV

- ConvertTo-Json / ConvertFrom-Json
- 使用 PowerShellYAML 模块读取 YAML（第三方）
- Import-Csv / Export-Csv 操作表格数据

示例保存对象为 JSON：

```powershell
Get-Process | Select-Object Name,Id,CPU | ConvertTo-Json -Depth 3 | Set-Content -Path processes.json -Encoding utf8
```

### 使用 SecretManagement 存储敏感信息

- Microsoft.PowerShell.SecretManagement 与 SecretStore 提供跨会话的安全存储。

安装并注册本地存储：

```powershell
Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser
Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name GitHubToken -Secret (Read-Host -AsSecureString)
```

读取：

```powershell
$token = Get-Secret -Name GitHubToken
```

### 常用正则与文本处理

- 使用 -match、-replace、Select-String 进行文本匹配。

示例提取电子邮件：

```powershell
'Contact: foo@example.com' -match '\b[\w.-]+@[\w.-]+\.\w{2,}\b'
$matches[0]
```

## 与其他工具的互操作

- 使用 Start-Process 启动外部程序并控制参数。
- 在脚本中调用 dotnet、python、node 等工具。

在 GitHub Actions 中使用 PowerShell（示例）：

```yaml
- name: Run PowerShell script
  shell: pwsh
  run: |
    ./scripts/ci.ps1
```

## 性能与最佳实践

- 避免在循环中重复使用外部命令，尽量先收集数据再批量处理。
- 使用 pipeline-friendly 的函数，输出对象而非打印字符串。
- 为脚本添加日志与重试逻辑。

示例重试封装：

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 2
    )

    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            return & $ScriptBlock
        } catch {
            if ($i -eq $MaxAttempts) { throw }
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}
```

## 常见陷阱与注意事项

- 执行策略（ExecutionPolicy）并不是安全边界；它只用于防止意外执行脚本。
- 路径分隔符在 Windows 与 Unix 上不同，优先使用 Join-Path 或 [IO.Path]::Combine。
- 字符编码：PowerShell Core 默认为 UTF-8，而 Windows PowerShell 使用 ANSI/UTF-16，注意文件读写编码。
- 当在管理员权限下运行脚本时，避免在无意中改写系统配置。

## 附录：常用一行命令速查表

- 查找文件包含关键字：

```powershell
Select-String -Path .\*.ps1 -Pattern 'TODO' -List
```

- 计算文件夹大小：

```powershell
Get-ChildItem -Recurse | Measure-Object -Property Length -Sum
```

- 批量替换文本：

```powershell
Get-ChildItem -Recurse -Filter *.txt | ForEach-Object { (Get-Content $_.FullName) -replace 'foo','bar' | Set-Content $_.FullName }
```

## 参考资料与进一步阅读

- PowerShell 官方文档: [https://learn.microsoft.com/powershell](https://learn.microsoft.com/powershell)
- PowerShell Gallery: [https://www.powershellgallery.com/](https://www.powershellgallery.com/)
- SecretManagement: [https://learn.microsoft.com/powershell/scripting/overview](https://learn.microsoft.com/powershell/scripting/overview)


---

作者: 借助 GitHub Copilot 助力编写
