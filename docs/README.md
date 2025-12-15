<!-- docs/README.md -->
<h1 align="center">Ops Errors — Documentation</h1>

<p align="center">
  <b>Centralized error logging for GitHub Actions, with reusable Bash helpers automatically loaded via <code>BASH_ENV</code>.</b>
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-errors">
    <img alt="Repository" src="https://img.shields.io/badge/GitHub-Repository-black" />
  </a>
  <a href="https://github.com/marketplace/actions/ops-errors">
    <img alt="Marketplace" src="https://img.shields.io/badge/GitHub-Marketplace-blue" />
  </a>
  <a href="https://github.com/Malnati/ops-errors/releases">
    <img alt="Releases" src="https://img.shields.io/github/v/release/Malnati/ops-errors" />
  </a>
</p>

<hr />

<h2>Overview</h2>

<p>
  <b>Malnati/ops-errors</b> is a composite action designed to remove duplicated Bash error-handling code from workflows and composite actions.
  It creates (or ensures) an error log file, exports <code>ERRORS_PATH</code>, and configures <code>BASH_ENV</code so subsequent
  <code>shell: bash</code> steps automatically load shared helper functions.
</p>

<ul>
  <li>Single place to store stderr logs on disk</li>
  <li>Reusable helpers across many steps without re-declaring functions</li>
  <li>Consistent formatting: timestamp + context + captured stderr</li>
</ul>

<hr />

<h2>How it works</h2>

<ol>
  <li>Ensures the error log file exists (creates directories and an empty file if needed).</li>
  <li>Exports <code>ERRORS_PATH</code> to <code>$GITHUB_ENV</code>.</li>
  <li>Exports <code>BASH_ENV</code> to <code>$GITHUB_ENV</code>, pointing to the action library file.</li>
  <li>Every next <code>shell: bash</code> step automatically sources that library.</li>
</ol>

<p>
  This pattern avoids repeating <code>append_error_log()</code> blocks in multiple steps.
</p>

<hr />

<h2>Installation</h2>

<p>
  Add <b>one</b> step at the beginning of your job:
</p>

<pre><code class="language-yaml">- name: "🧯 Setup error logging"
  uses: Malnati/ops-errors@v1.0.0
  with:
    errors_path: .github/workflows/errors.log
</code></pre>

<p>
  From that point on, any step using <code>shell: bash</code> will have:
</p>

<ul>
  <li><code>ERRORS_PATH</code> environment variable</li>
  <li><code>append_error_log</code> function</li>
  <li><code>with_error_log</code> function</li>
</ul>

<hr />

<h2>Inputs</h2>

<ul>
  <li>
    <code>errors_path</code> (optional) — Path to the error log file.
    Default: <code>.github/workflows/errors.log</code>
  </li>
</ul>

<h2>Outputs</h2>

<ul>
  <li><code>errors_path</code> — Resolved error log file path.</li>
  <li><code>bash_env</code> — Library file used as <code>BASH_ENV</code>.</li>
</ul>

<hr />

<h2>Helpers</h2>

<h3><code>append_error_log &lt;context&gt; &lt;stderr_file&gt;</code></h3>

<p>
  Appends a timestamped section into <code>$ERRORS_PATH</code> with the provided <code>context</code> and the content of <code>stderr_file</code>.
  If <code>ERRORS_PATH</code> is empty or the stderr file is empty, it does nothing.
</p>

<h3><code>with_error_log &lt;context&gt; &lt;command...&gt;</code></h3>

<p>
  Runs a command capturing stderr to a temporary file. If the command fails, it appends the captured stderr into <code>$ERRORS_PATH</code>
  and returns exit code <code>1</code>. On success it returns <code>0</code>.
</p>

<hr />

<h2>Example workflow</h2>

<pre><code class="language-yaml">name: "Example - ops-errors"

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  demo:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: "🧯 Setup error logging"
        uses: Malnati/ops-errors@v1.0.0
        with:
          errors_path: .github/workflows/errors.log

      - name: "❌ Logged failure (captures stderr)"
        shell: bash
        run: |
          set -euo pipefail
          with_error_log "demo: failing command" bash -lc 'echo "Boom" >&2; exit 1'

      - name: "📄 Print error log preview"
        shell: bash
        run: |
          set -euo pipefail
          echo "ERRORS_PATH=$ERRORS_PATH"
          test -f "$ERRORS_PATH"
          head -n 80 "$ERRORS_PATH" || true
</code></pre>

<hr />

<h2>Recommended usage patterns</h2>

<h3>Wrap GitHub CLI commands</h3>

<pre><code class="language-yaml">- name: "🔍 PR info (with logging)"
  shell: bash
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    set -euo pipefail
    with_error_log "pr_info: gh auth status" gh auth status
    with_error_log "pr_info: gh pr view" gh pr view 123 --json url,title
</code></pre>

<h3>Manual capture (when you already have a file)</h3>

<pre><code class="language-yaml">- name: "🧾 Manual stderr capture"
  shell: bash
  run: |
    set -euo pipefail
    err="$(mktemp)"
    bash -lc 'echo "Something happened" >&2; exit 0' 2>"$err" || true
    append_error_log "demo: non-fatal stderr" "$err" || true
    rm -f "$err"
</code></pre>

<hr />

<h2>Notes</h2>

<ul>
  <li><b>Use <code>shell: bash</code></b> in steps that rely on <code>BASH_ENV</code> auto-loading.</li>
  <li>The log file is appended across steps; rotate or clean it if needed.</li>
</ul>

<hr />

<p align="center">
  <sub>Designed for composite actions and workflows that require consistent, low-noise, reusable error logging.</sub>
</p>
