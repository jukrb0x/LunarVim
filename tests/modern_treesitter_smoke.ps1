#Requires -Version 7.1
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Root = Join-Path $env:TEMP "lvim-modern-treesitter-smoke"
$Runtime = Join-Path $Root "data\lunarvim"
$Config = Join-Path $Root "config\lvim"
$Cache = Join-Path $Root "cache\lvim"
$State = Join-Path $Root "state\lvim"
$Log = Join-Path $Root "smoke.log"

Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $Root
New-Item -ItemType Directory -Force -Path $Runtime, $Config, $Cache, $State | Out-Null

@'
lvim.builtin.treesitter.highlight.enable = true
lvim.builtin.treesitter.indent.enable = true
lvim.builtin.illuminate.active = true
lvim.builtin.indentlines.active = true
lvim.lsp.automatic_configuration.skipped_servers = { "lua_ls" }
'@ | Set-Content -LiteralPath (Join-Path $Config "config.lua") -Encoding UTF8

$env:XDG_DATA_HOME = Join-Path $Root "data"
$env:XDG_CONFIG_HOME = Join-Path $Root "config"
$env:XDG_CACHE_HOME = Join-Path $Root "cache"
$env:XDG_STATE_HOME = Join-Path $Root "state"
$env:LUNARVIM_RUNTIME_DIR = $Runtime
$env:LUNARVIM_CONFIG_DIR = $Config
$env:LUNARVIM_CACHE_DIR = $Cache
$env:LUNARVIM_BASE_DIR = $RepoRoot
$env:Path = "$HOME\.local\bin;$env:Path"

$LuaFile = Join-Path $Root "smoke.lua"
@'
local function assert_true(name, ok, detail)
  if not ok then
    error(name .. " failed" .. (detail and (": " .. tostring(detail)) or ""))
  end
end

local ts_path = vim.env.LUNARVIM_RUNTIME_DIR .. "/site/pack/lazy/opt/nvim-treesitter"
local branch = vim.fn.system({ "git", "-C", ts_path, "branch", "--show-current" }):gsub("%s+", "")
assert_true("nvim-treesitter branch", branch == "main", branch)

local ok_ts = pcall(require, "nvim-treesitter")
assert_true("require nvim-treesitter", ok_ts)

local ok_configs = pcall(require, "nvim-treesitter.configs")
assert_true("legacy configs compatibility", ok_configs)

local ok_query = pcall(require, "nvim-treesitter.query")
assert_true("legacy query compatibility", ok_query)

local ok_ts_utils = pcall(require, "nvim-treesitter.ts_utils")
assert_true("legacy ts_utils compatibility", ok_ts_utils)

local ok_locals = pcall(require, "nvim-treesitter.locals")
assert_true("legacy locals compatibility", ok_locals)

local ok_hover, hover_err = pcall(function()
  vim.lsp.util.open_floating_preview({ "```lua", "local x = 1", "```" }, "markdown", { focus = false })
end)
assert_true("markdown hover", ok_hover, hover_err)

print("MODERN_TREESITTER_SMOKE_OK")
'@ | Set-Content -LiteralPath $LuaFile -Encoding UTF8

$Output = & nvim --headless -u (Join-Path $RepoRoot "init.lua") "+luafile $LuaFile" +qa 2>&1
$Output | Tee-Object -FilePath $Log
$OutputText = $Output -join "`n"

if ($LASTEXITCODE -ne 0) {
    throw "Smoke test failed with exit code $LASTEXITCODE. See $Log"
}

if ($OutputText -notmatch "MODERN_TREESITTER_SMOKE_OK") {
    throw "Smoke test did not print success marker. See $Log"
}

$Sample = Join-Path $Root "sample.lua"
"local x = 1" | Set-Content -LiteralPath $Sample -Encoding UTF8

$FileOutput = & nvim --headless -u (Join-Path $RepoRoot "init.lua") $Sample "+luafile $LuaFile" +qa 2>&1
$FileOutput | Tee-Object -FilePath $Log -Append
$FileOutputText = $FileOutput -join "`n"

if ($LASTEXITCODE -ne 0) {
    throw "File-open smoke test failed with exit code $LASTEXITCODE. See $Log"
}

if ($FileOutputText -notmatch "MODERN_TREESITTER_SMOKE_OK") {
    throw "File-open smoke test did not print success marker. See $Log"
}

if ($FileOutputText -match "nvim-treesitter\\.query.*not found|attempt to call method 'range'|Failed to source|E5108|define_modules") {
    throw "File-open smoke test hit a treesitter compatibility error. See $Log"
}
