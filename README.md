# Configured-owner authority repair qualification

Public-source-only build harness for OpenClaw 2026.10.5, MIT licensed.
Upstream: https://github.com/openclaw/openclaw
Pinned upstream: 1b58cb9a1b4f4353e1add63c8506db4d890962e8
The patch contains only four source/test file changes. No source history, private configuration, reports, credentials, or live deployment is included.

Manually dispatched workflow uses only the standard public ubuntu-24.04 runner (free compute), read-only repository token, no secrets, no cache, concurrency one, and a 90-minute timeout. It builds the canonical package, validates and disposable-installs it. It does not publish to npm or Releases or activate a Gateway.

Artifact upload is limited to the validated software tarball and its basename-only SHA256SUMS, with a 250 MiB total ceiling and one-day retention. Dispatch requires independently verified free storage headroom and a zero-dollar overage budget; no billing settings are changed by this harness. Download and verify the candidate before expiry. Logs and job summaries are not billed artifact storage per GitHub Actions billing documentation.

https://docs.github.com/en/billing/concepts/product-billing/github-actions

Synthetic tests are not genuine post-activation Discord proof. Activation and rollback preparation require separate approval.
