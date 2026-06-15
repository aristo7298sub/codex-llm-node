<#
.SYNOPSIS
  CopilotProxy 助手 — 检查 / 启动 / 测试本地 Codex LLM 节点。
  配套技能：codex-llm-node。用前台模式（本机 daemon 的 status/stop 因 wmic 被移除而失效）。

.EXAMPLE
  .\proxy.ps1 status              # 探活端口 4399
.EXAMPLE
  .\proxy.ps1 start               # 前台启动（保持窗口开着）
.EXAMPLE
  .\proxy.ps1 start -Verbose      # 前台启动 + 详细日志
.EXAMPLE
  .\proxy.ps1 test                # 实测一次推理
.EXAMPLE
  .\proxy.ps1 test -Model claude-opus-4.8
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('status', 'start', 'test', 'models')]
  [string]$Action = 'status',

  [string]$Model = 'gpt-5.3-codex',

  [int]$Port = 4399,

  # 默认指向本脚本同级目录的 CopilotProxy/（日常运行位置）；不存在时需手动传入 -ProxyDir。
  [string]$ProxyDir = $(
    $sibling = Join-Path (Split-Path $PSScriptRoot -Parent) 'CopilotProxy'
    if (Test-Path $sibling) { $sibling } else { Join-Path (Split-Path $PSScriptRoot -Parent) 'CopilotProxy' }
  )
)

$ErrorActionPreference = 'Stop'
$base = "http://localhost:$Port"

function Test-Proxy {
  try { $null = Invoke-RestMethod "$base/" -TimeoutSec 5; return $true }
  catch { return $false }
}

switch ($Action) {
  'status' {
    if (Test-Proxy) {
      $count = (Invoke-RestMethod "$base/v1/models" -TimeoutSec 5).data.Count
      Write-Host "[OK] 代理在线 $base — $count 个模型可用" -ForegroundColor Green
    }
    else {
      Write-Host "[--] 代理未运行（$base 无响应）。用 '.\proxy.ps1 start' 启动。" -ForegroundColor Yellow
    }
  }

  'models' {
    if (-not (Test-Proxy)) { Write-Host "代理未运行。" -ForegroundColor Yellow; break }
    (Invoke-RestMethod "$base/v1/models").data.id | Sort-Object
  }

  'start' {
    if (Test-Proxy) { Write-Host "代理已在 $base 运行，无需重复启动。" -ForegroundColor Green; break }
    if (-not (Test-Path $ProxyDir)) { throw "找不到代理目录：$ProxyDir" }
    Push-Location $ProxyDir
    try {
      $args = @('run', 'src/main.ts', 'start')
      if ($PSBoundParameters.ContainsKey('Verbose')) { $args += '--verbose' }
      Write-Host "前台启动代理（Ctrl+C 停止）：bun $($args -join ' ')" -ForegroundColor Cyan
      & bun @args
    }
    finally { Pop-Location }
  }

  'test' {
    if (-not (Test-Proxy)) { Write-Host "代理未运行。先 '.\proxy.ps1 start'。" -ForegroundColor Yellow; break }
    $body = @{ model = $Model; input = "Reply with exactly: PROXY_OK" } | ConvertTo-Json
    try {
      $r = Invoke-RestMethod "$base/v1/responses" -Method Post -ContentType 'application/json' `
        -Headers @{ Authorization = 'Bearer dummy' } -Body $body -TimeoutSec 120
      $text = ($r.output | Where-Object type -eq 'message' | ForEach-Object { $_.content.text }) -join ''
      Write-Host "[$Model] -> $text" -ForegroundColor Green
    }
    catch {
      Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
      if ($_.ErrorDetails) { $_.ErrorDetails.Message }
    }
  }
}
