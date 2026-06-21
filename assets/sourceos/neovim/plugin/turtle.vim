" TurtleTerm Neovim/Vim plugin
" Bridges the editor to the TurtleTerm agent layer.

if exists('g:loaded_turtleterm') | finish | endif
let g:loaded_turtleterm = 1

" ---------------------------------------------------------------------------
" Utilities
" ---------------------------------------------------------------------------

function! s:json_get(json_str, key) abort
  let m = matchlist(a:json_str, '"' . a:key . '":\s*"\([^"]*\)"')
  return empty(m) ? '' : m[1]
endfunction

function! s:json_get_nested(json_str, outer, inner) abort
  " Extract inner key from a nested object value
  let outer_pat = '"' . a:outer . '":\s*{\([^}]*\)}'
  let m = matchlist(a:json_str, outer_pat)
  if empty(m) | return '' | endif
  return s:json_get('{' . m[1] . '}', a:inner)
endfunction

function! s:show_float(title, lines) abort
  let width = min([max(map(copy(a:lines), 'len(v:val)')) + 4, 84])
  let height = min([len(a:lines) + 2, 24])
  if has('nvim')
    let buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(buf, 0, -1, v:true, ['  ' . a:title, repeat('─', width)] + map(copy(a:lines), '"  " . v:val'))
    let opts = {
      \ 'relative': 'editor',
      \ 'width': width,
      \ 'height': height,
      \ 'col': (&columns - width) / 2,
      \ 'row': (&lines - height) / 2,
      \ 'anchor': 'NW',
      \ 'style': 'minimal',
      \ 'border': 'rounded',
    \ }
    let win = nvim_open_win(buf, v:true, opts)
    call nvim_buf_set_keymap(buf, 'n', 'q', ':bd!<CR>', {'noremap': v:true, 'silent': v:true})
    call nvim_buf_set_keymap(buf, 'n', '<Esc>', ':bd!<CR>', {'noremap': v:true, 'silent': v:true})
    setlocal buftype=nofile noswapfile nospell nonumber norelativenumber
  else
    echomsg a:title . ': ' . join(a:lines, ' | ')
  endif
endfunction

function! s:run_agentctl(args, input) abort
  if a:input !=# ''
    return system('echo ' . shellescape(a:input) . ' | turtle-agentctl ' . a:args . ' 2>/dev/null')
  endif
  return system('turtle-agentctl ' . a:args . ' 2>/dev/null')
endfunction

" ---------------------------------------------------------------------------
" :TurtleExplain — explain visual selection or current line
" ---------------------------------------------------------------------------

function! turtle#explain() abort
  let sel = ''
  if mode() ==# 'v' || mode() ==# 'V' || mode() ==# "\<C-V>"
    let [l1, c1] = [line("'<"), col("'<")]
    let [l2, c2] = [line("'>"), col("'>")]
    let selected = getline(l1, l2)
    if !empty(selected)
      let selected[-1] = selected[-1][:c2 - 1]
      let selected[0] = selected[0][c1 - 1:]
      let sel = join(selected, "\n")
    endif
  endif
  if sel ==# ''
    let sel = getline('.')
  endif
  if sel ==# ''
    echo 'TurtleTerm: nothing to explain'
    return
  endif
  echo 'TurtleTerm: explaining...'
  let out = s:run_agentctl('explain-selection', sel)
  let explanation = s:json_get_nested(out, 'data', 'explanation')
  if explanation ==# ''
    let explanation = out !=# '' ? out : '(no response from AI)'
  endif
  call s:show_float('TurtleTerm Explain', split(explanation, "\n"))
endfunction

" ---------------------------------------------------------------------------
" :TurtleRun — send command to TurtleTerm pane for confirmation
" ---------------------------------------------------------------------------

function! turtle#run(...) abort
  let cmd = a:0 > 0 ? join(a:000, ' ') : getline('.')
  if cmd ==# ''
    echo 'TurtleTerm: no command'
    return
  endif
  let out = s:run_agentctl('execute-with-confirmation ' . shellescape(cmd), '')
  let status = s:json_get(out, 'status')
  echo 'TurtleTerm: ' . (status !=# '' ? status : 'sent → ' . cmd[:60])
endfunction

" ---------------------------------------------------------------------------
" :TurtleNL — natural language to shell command
" ---------------------------------------------------------------------------

function! turtle#nl(...) abort
  let text = a:0 > 0 ? join(a:000, ' ') : ''
  if text ==# ''
    let text = input('NL→shell: ')
  endif
  if text ==# '' | return | endif
  echo 'TurtleTerm: translating...'
  let out = s:run_agentctl('nl-to-shell ' . shellescape(text), '')
  let cmd = s:json_get_nested(out, 'data', 'command')
  if cmd ==# ''
    echo 'TurtleTerm: no command generated'
    return
  endif
  " Yank to unnamed register and put on command line
  let @" = cmd
  call feedkeys(':!' . cmd, 'n')
endfunction

" ---------------------------------------------------------------------------
" :TurtleContext — send buffer context to agentd and show response
" ---------------------------------------------------------------------------

function! turtle#context() abort
  let ctx_lines = getline(max([1, line('.') - 10]), min([line('$'), line('.') + 10]))
  let ctx = join(ctx_lines, "\n")
  let meta = 'file=' . expand('%:p') . ' ft=' . &filetype . ' line=' . line('.')
  let prompt = '[' . meta . "]\n" . ctx
  echo 'TurtleTerm: fetching context...'
  let out = s:run_agentctl('noetica-query ' . shellescape(prompt), '')
  let reply = s:json_get_nested(out, 'data', 'response')
  if reply ==# '' | let reply = out | endif
  call s:show_float('TurtleTerm Context', split(reply !=# '' ? reply : '(no response)', "\n"))
endfunction

" ---------------------------------------------------------------------------
" :TurtleStatus
" ---------------------------------------------------------------------------

function! turtle#status() abort
  let out = s:run_agentctl('--stdio ping', '')
  let ver = s:json_get(out, 'version')
  let noetica = s:json_get_nested(out, 'data', 'noetica_reachable')
  echo 'TurtleTerm agent v' . (ver !=# '' ? ver : '?') . ' | noetica=' . (noetica !=# '' ? noetica : '?')
endfunction

" ---------------------------------------------------------------------------
" :SynapseIQLSP — print lspconfig snippet for synapseiq-lsp
" ---------------------------------------------------------------------------

function! turtle#synapseiq_lsp_snippet() abort
  let snippet = [
    \ 'Add to your Neovim config (requires nvim-lspconfig):',
    \ '',
    \ '  local lspconfig = require("lspconfig")',
    \ '  local configs = require("lspconfig.configs")',
    \ '',
    \ '  if not configs.synapseiq then',
    \ '    configs.synapseiq = {',
    \ '      default_config = {',
    \ '        cmd = { "synapseiq-lsp" },',
    \ '        filetypes = {',
    \ '          "python", "typescript", "javascript",',
    \ '          "lua", "rust", "go", "sh", "json", "yaml",',
    \ '          "ruby", "java", "cpp", "c",',
    \ '        },',
    \ '        root_dir = lspconfig.util.root_pattern(".git", "."),',
    \ '        single_file_support = true,',
    \ '        settings = {},',
    \ '      },',
    \ '    }',
    \ '  end',
    \ '  lspconfig.synapseiq.setup({})',
    \ '',
    \ 'Or with vim.lsp.start (no lspconfig dependency):',
    \ '',
    \ '  vim.api.nvim_create_autocmd("FileType", {',
    \ '    pattern = { "python","typescript","javascript","lua","rust","go" },',
    \ '    callback = function(ev)',
    \ '      vim.lsp.start({',
    \ '        name = "synapseiq-lsp",',
    \ '        cmd = { "synapseiq-lsp" },',
    \ '        root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),',
    \ '      })',
    \ '    end,',
    \ '  })',
  \ ]
  call s:show_float('SynapseIQ LSP Setup', snippet)
endfunction

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------

command! -range TurtleExplain call turtle#explain()
command! -nargs=* TurtleRun call turtle#run(<f-args>)
command! -nargs=* TurtleNL call turtle#nl(<f-args>)
command! TurtleContext call turtle#context()
command! TurtleStatus call turtle#status()
command! SynapseIQLSP call turtle#synapseiq_lsp_snippet()

" ---------------------------------------------------------------------------
" Key mappings (only if not already mapped)
" ---------------------------------------------------------------------------

if !hasmapto('<Plug>TurtleExplain')
  vmap <unique> <Leader>te :TurtleExplain<CR>
  nmap <unique> <Leader>te :TurtleExplain<CR>
endif
if !hasmapto('<Plug>TurtleRun')
  nmap <unique> <Leader>tr :TurtleRun<CR>
endif
if !hasmapto('<Plug>TurtleNL')
  nmap <unique> <Leader>tn :TurtleNL<CR>
endif
