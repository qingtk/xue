<#
示例：使用 SecretManagement 读取 GitHub 令牌并创建 Issue
先确保安装并注册 SecretStore 或其它 Secret 管理器：
Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser
Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name GitHubToken -Secret (Read-Host -AsSecureString)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Owner,

    [Parameter(Mandatory=$true)]
    [string]$Repo,

    [Parameter(Mandatory=$true)]
    [string]$Title,

    [string]$Body = ''
)

try {
    # 从 SecretManagement 获取令牌（返回 SecureString 或 PSCredential 取决于存储方式）
    $secret = Get-Secret -Name GitHubToken -ErrorAction Stop
    if ($secret -is [System.Security.SecureString]) {
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } elseif ($secret -is [Microsoft.PowerShell.SecretManagement.SecretInfo]) {
        # 若返回的是包装类型，尝试提取
        $token = $secret.Secret
    } else {
        $token = $secret.ToString()
    }

    $bodyObj = @{ title = $Title; body = $Body }
    $json = $bodyObj | ConvertTo-Json

    $uri = "https://api.github.com/repos/$Owner/$Repo/issues"
    $headers = @{ Authorization = "Bearer $token"; 'User-Agent' = 'PowerShell'; 'Accept' = 'application/vnd.github+json' }

    $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $json -ContentType 'application/json' -Headers $headers -ErrorAction Stop
    Write-Output "Issue 创建成功： $($resp.html_url)"
} catch {
    Write-Error "创建 Issue 失败：$($_.Exception.Message)"
    exit 1
}
