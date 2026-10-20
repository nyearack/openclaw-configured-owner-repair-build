# Configured-owner authority repair qualification

Public-source-only build harness for OpenClaw 2026.10.5, MIT licensed.
Upstream: https://github.com/openclaw/openclaw
Pinned upstream: 1b58cb9a1b4f4353e1add63c8506db4d890962e8
The patch contains only four source/test file changes. No source history, private configuration, reports, credentials, or live deployment is included.

Manually dispatched workflow uses only the standard public ubuntu-24.04 runner (free compute), read-only repository token, no secrets, no cache, concurrency one, and a 90-minute timeout. It builds the canonical package, validates and disposable-installs it. It does not publish to npm or Releases or activate a Gateway.

Artifact upload is deliberately absent: account shared-storage billing entitlement could not be verified with the available read-only billing access. The package remains ephemeral on the runner. A successful run qualifies software but does not make an installation artifact available. Artifact retention/upload must be added only after no-cost storage entitlement is established. Logs and job summaries are not billed artifact storage per GitHub Actions billing documentation.

https://docs.github.com/en/billing/concepts/product-billing/github-actions

Synthetic tests are not genuine post-activation Discord proof. Activation and rollback preparation require separate approval.
