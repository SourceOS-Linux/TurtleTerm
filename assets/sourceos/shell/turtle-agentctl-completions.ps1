# TurtleTerm PowerShell tab completions for turtle-agentctl, turtle-copilot, turtle-gh

Register-ArgumentCompleter -Native -CommandName 'turtle-agentctl' -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  $commands = @(
    'ping','surfaces','plan-create','plan-status','plan-next','plan-list','plan-cancel',
    'explain-selection','nl-to-shell','ai-complete','session-chat','session-to-pr',
    'pre-exec-risk','shellcheck-lint','detect-secrets','env-inspect',
    'perf-record','perf-stats','output-export','output-search',
    'file-tree','workflow-detect',
    'gitea-status','gitea-repo-list','gitea-pr-create','gitea-pr-list',
    'gitea-issue-create','gitea-release-create','gitea-snippet-create',
    'gitea-ci-runs','gitea-ci-watch',
    'copilot-start','copilot-stop','copilot-status','copilot-chat',
    'copilot-configure','copilot-suggest','copilot-backends',
    'gh-repo-create','gh-repo-fork','gh-repo-view',
    'gh-pr-checkout','gh-pr-merge','gh-pr-close','gh-pr-comment',
    'gh-issue-list','gh-issue-close','gh-issue-comment',
    'gh-release-list','gh-release-ai-changelog','gh-workflow-list',
    'gh-secret-list','gh-label-list','gh-label-create',
    'gh-search','gh-status','gh-api',
    'workspace-scan','env-load','env-set','env-list','env-export',
    'diagnose','chain-run','chain-list',
    'bg-plan-start','bg-plan-status','bg-plan-list','bg-plan-cancel',
    'webhook-add','webhook-list','webhook-remove','webhook-dispatch',
    'scratchpad-write','scratchpad-read','scratchpad-list',
    'cost-record','cost-stats','history-index','history-search',
    'process-watch','process-watch-list','dashboard'
  )
  $commands | Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -Native -CommandName 'turtle-copilot' -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  $commands = @('start','stop','status','chat','suggest','backends','use','config')
  $commands | Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -Native -CommandName 'turtle-gh' -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  $commands = @('repo','pr','issue','release','gist','run','workflow','secret','label','search','status','auth','api')
  $commands | Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
