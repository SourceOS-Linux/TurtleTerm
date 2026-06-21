#compdef turtle-gh
# turtle-gh zsh completion

_turtle_gh() {
  local -a subcmds
  subcmds=(
    'repo:Repository operations (create/fork/view/clone)'
    'pr:Pull request operations'
    'issue:Issue operations'
    'release:Release management'
    'gist:Snippet/gist management'
    'run:CI run operations'
    'workflow:Workflow management'
    'secret:Repository secrets'
    'label:Label management'
    'search:Search repos, issues, PRs'
    'status:Show forge status'
    'auth:Authentication status'
    'api:Raw API call'
  )

  local state
  _arguments '1: :->cmd' '*: :->args' && return 0

  case $state in
    cmd)
      _describe 'turtle-gh command' subcmds ;;
    args)
      case $words[2] in
        repo)
          local -a repo_cmds
          repo_cmds=('create:Create a repo' 'fork:Fork current repo' 'view:View repo details' 'clone:Clone a repo')
          _describe 'repo subcommand' repo_cmds ;;
        pr)
          local -a pr_cmds
          pr_cmds=('create:Create PR (--ai for AI body)' 'list:List PRs' 'view:View a PR' 'checkout:Checkout PR branch' 'merge:Merge PR' 'close:Close PR' 'comment:Add comment' 'diff:Show diff')
          _describe 'pr subcommand' pr_cmds ;;
        issue)
          local -a issue_cmds
          issue_cmds=('create:Create issue (--ai for labels)' 'list:List issues' 'view:View issue' 'close:Close issue' 'comment:Add comment')
          _describe 'issue subcommand' issue_cmds ;;
        release)
          local -a rel_cmds
          rel_cmds=('create:Create release (--ai-changelog for AI)' 'list:List releases')
          _describe 'release subcommand' rel_cmds ;;
        run)
          local -a run_cmds
          run_cmds=('list:List CI runs' 'watch:Watch a run' 'cancel:Cancel a run')
          _describe 'run subcommand' run_cmds ;;
        workflow)
          local -a wf_cmds
          wf_cmds=('list:List workflows' 'run:Trigger a workflow')
          _describe 'workflow subcommand' wf_cmds ;;
        search)
          local -a kinds
          kinds=('repos' 'issues' 'prs' 'code')
          _describe 'search kind' kinds ;;
        auth)
          local -a auth_cmds
          auth_cmds=('status:Show auth status' 'token:Print current token')
          _describe 'auth subcommand' auth_cmds ;;
      esac ;;
  esac
}

_turtle_gh "$@"
