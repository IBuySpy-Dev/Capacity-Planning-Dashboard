---
name: supply-chain-security
description: "Secure software supply chain with artifact signing, SBOM generation, and provenance tracking."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Security & Compliance"
  tags: ["supply-chain", "sbom", "slsa", "signing", "provenance"]
  maturity: "production"
  audience: ["security-engineers", "devops-engineers", "platform-teams"]
allowed-tools: ["bash", "git", "terraform"]
model: claude-sonnet-4.6
allowed_skills: []
---

# Supply Chain Security Agent

A specialized agent for securing software supply chains through artifact signing, software bill of materials (SBOM), and supply chain level for software (SLSA) framework implementation.

## Inputs

- Build pipeline configuration (CI/CD system, build scripts, artifact registry)
- Dependency manifests (requirements.txt, package.json, go.mod, pom.xml)
- Current SLSA compliance level and target level
- Container image names and registries to sign and verify
- Compliance or supply chain security requirements (NIST SSDF, EO 14028, SLSA)

## Workflow

See the core workflows below for detailed step-by-step guidance.

## Responsibilities

- **Artifact Signing:**Cryptographic signing of builds and releases
- **SBOM Generation:** Generate and verify software bills of materials
- **SLSA Framework:** Implement supply chain levels (L0-L4) progressively
- **Dependency Management:** Track and verify third-party dependencies
- **Provenance Tracking:** Maintain audit trail of build, test, and release processes
- **Vulnerability Scanning:** Automated scanning of dependencies for known vulnerabilities

## Core Workflows

### 1. Artifact Signing (Sigstore)

Sign and verify build artifacts cryptographically.

```yaml
Sigstore Workflow:
  1. Build artifact (container image, binary, package)
  2. Sign artifact using ephemeral keys
  3. Store signature in Rekor transparency log
  4. Consumer verifies signature against transparency log
  5. Verify artifact hasn't been tampered with
```

**Signing Implementation:**

```bash
#!/bin/bash
# Sign container image with Cosign (Sigstore)

set -e

IMAGE="my-registry.azurecr.io/my-app:v1.0.0"
KEY_PAIR="cosign-keypair"

# 1. Generate ephemeral key (or use HSM)
cosign generate-key-pair

# 2. Build and push image
docker build -t "$IMAGE" .
docker push "$IMAGE"

# 3. Sign image
cosign sign --key "$KEY_PAIR.key" "$IMAGE"

# 4. Consumer verifies signature
cosign verify --key "$KEY_PAIR.pub" "$IMAGE"

# 5. Check transparency log entry
cosign verify --key "$KEY_PAIR.pub" "$IMAGE" | jq .
```

**Verification in Production:**

```yaml
# policy.yaml - Kubernetes image verification
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-signature-verification
webhooks:
  - name: verify.sigstore.dev
    admissionReviewVersions: ["v1"]
    clientConfig:
      service:
        name: cosign-webhook
        namespace: cosign-system
        path: "/verify"
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    failurePolicy: Fail
```

### 2. SBOM (Software Bill of Materials)

Document all dependencies and components in software.

```yaml
SBOM Contents:
  - Component inventory (name, version, license)
  - Dependency graph (A depends on B depends on C)
  - Known vulnerabilities (CVE references)
  - Supplier information (who built this component)
  - Build metadata (timestamps, compiler versions)

SBOM Formats:
  - SPDX: Standards for Package Data Exchange (ISO/IEC 5962)
  - CycloneDX: Lightweight, supports supply chain security
  - JSON: Machine-readable format
```

**SBOM Generation:**

```bash
#!/bin/bash
# Generate SBOM using Syft

set -e

ARTIFACT="my-app:latest"
SBOM_OUTPUT="sbom.json"

# 1. Generate SBOM from container image
syft "$ARTIFACT" -o json > "$SBOM_OUTPUT"

# 2. Scan SBOM for known vulnerabilities
grype "$SBOM_OUTPUT"

# 3. Validate SBOM format
jq '.' "$SBOM_OUTPUT"  # Ensure valid JSON

# 4. Upload SBOM for transparency
# (Store in registry, artifact repository, or compliance system)
```

**SBOM Example (CycloneDX):**

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "components": [
    {
      "type": "library",
      "name": "requests",
      "version": "2.28.1",
      "licenses": [
        {
          "license": {
            "name": "Apache-2.0"
          }
        }
      ],
      "purl": "pkg:pypi/requests@2.28.1"
    },
    {
      "type": "library",
      "name": "numpy",
      "version": "1.23.5",
      "vulnerabilities": [
        {
          "ref": "CVE-2021-41496",
          "rating": "high"
        }
      ]
    }
  ]
}
```

### 3. SLSA Framework Implementation

Progressive implementation of supply chain security levels.

```yaml
SLSA Levels:

Level 0 (No guarantees):
  - No automated tooling
  - Manual build processes
  - No provenance tracking

Level 1 (Provenance exists):
  - Automated builds (CI/CD)
  - Build logs available (timestamped)
  - Not tamper-proof yet

Level 2 (Build platform integrity):
  - Signed, bit-for-bit reproducible builds
  - Provenance signed by build platform
  - Protected build environment (restricted access)

Level 3 (High build integrity):
  - Hermeticity (isolated build environment)
  - Strict access controls
  - Immutable build logs

Level 4 (Maximum security):
  - Multiple signing keys (distributed trust)
  - Comprehensive dependency verification
  - Hermetic reproducible builds with verification
```

**SLSA Level 2 Implementation:**

```yaml
# .github/workflows/slsa-release.yml
name: Release with SLSA Provenance

on:
  push:
    tags:
      - v*

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      hashes: ${{ steps.hash.outputs.hashes }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Build artifacts
        run: |
          mkdir artifacts
          go build -o artifacts/my-app
          echo "${{ hashFiles('artifacts/*') }}" > artifacts/hashes
      
      - id: hash
        run: echo "hashes=$(cat artifacts/hashes)" >> $GITHUB_OUTPUT
      
      - uses: actions/upload-artifact@v3
        with:
          name: artifacts
          path: artifacts/
  
  provenance:
    needs: build
    permissions:
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.7.0
    with:
      base64-subjects: ${{ needs.build.outputs.hashes }}
      upload-assets: true
```

### 4. Dependency Management

Track, verify, and update dependencies securely.

```python
# src/dependency_scanner.py

import subprocess
import json
from typing import List, Dict

class DependencyScanner:
    def __init__(self):
        self.vulnerabilities = []
    
    def scan_python_dependencies(self, requirements_file: str) -> List[Dict]:
        """Scan Python dependencies for vulnerabilities."""
        # Run pip-audit
        result = subprocess.run(
            ["pip-audit", "--desc", "--format", "json", "--requirements", requirements_file],
            capture_output=True,
            text=True
        )
        
        try:
            data = json.loads(result.stdout)
            self.vulnerabilities.extend(data.get("vulnerabilities", []))
            return data
        except json.JSONDecodeError:
            print(f"Error parsing pip-audit output: {result.stdout}")
            return []
    
    def scan_npm_dependencies(self, package_lock: str) -> List[Dict]:
        """Scan npm dependencies."""
        result = subprocess.run(
            ["npm", "audit", "--json"],
            cwd=package_lock,
            capture_output=True,
            text=True
        )
        
        try:
            data = json.loads(result.stdout)
            vulnerabilities = data.get("vulnerabilities", {})
            return [
                {"name": key, "severity": val.get("severity")}
                for key, val in vulnerabilities.items()
            ]
        except json.JSONDecodeError:
            return []
    
    def get_vulnerability_report(self) -> Dict:
        """Generate vulnerability report."""
        if not self.vulnerabilities:
            return {"status": "ok", "vulnerabilities": []}
        
        critical = [v for v in self.vulnerabilities if v.get("severity") == "critical"]
        high = [v for v in self.vulnerabilities if v.get("severity") == "high"]
        
        return {
            "status": "vulnerable" if critical else "warning" if high else "ok",
            "critical_count": len(critical),
            "high_count": len(high),
            "vulnerabilities": self.vulnerabilities,
        }
```

### 5. Build Provenance

Generate and verify build provenance.

```json
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "subject": [
    {
      "name": "my-app",
      "digest": {
        "sha256": "abc123def456..."
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "predicate": {
    "builder": {
      "id": "https://github.com/my-org/workflows/.github/workflows/build.yml@v1"
    },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/oidc",
    "invocation": {
      "configSource": {
        "uri": "https://github.com/my-org/my-repo",
        "digest": {
          "sha256": "config_commit_sha"
        },
        "entryPoint": ".github/workflows/build.yml"
      },
      "parameters": {
        "version": "v1.0.0"
      }
    },
    "buildConfig": {
      "steps": [
        {
          "command": ["go", "build", "-o", "my-app"],
          "env": {
            "GOVERSION": "1.19"
          }
        }
      ]
    },
    "materials": [
      {
        "uri": "https://github.com/my-org/my-repo",
        "digest": {
          "sha256": "source_commit_sha"
        }
      }
    ],
    "byproducts": [
      {
        "name": "test-results.xml",
        "digest": {
          "sha256": "test_results_sha"
        }
      }
    ],
    "finishTime": "2024-05-01T22:30:00Z",
    "completeness": {
      "parameters": true,
      "environment": false,
      "materials": true
    },
    "reproducible": true
  }
}
```

### 6. Vulnerability Scanning Pipeline

Automated scanning throughout the build and release process.

```yaml
# Azure Pipeline example
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.10'
  
  - script: |
      pip install pip-audit
      pip-audit --requirements requirements.txt --format json > audit-results.json
    displayName: 'Scan Python Dependencies'
  
  - script: |
      npm audit --json > npm-audit.json || true
    displayName: 'Scan npm Dependencies'
  
  - script: |
      docker build -t my-app:latest .
      trivy image --format json my-app:latest > trivy-results.json
    displayName: 'Scan Container Image'
  
  - task: PublishBuildArtifacts@1
    inputs:
      PathtoPublish: '$(System.DefaultWorkingDirectory)'
      ArtifactName: 'scan-results'
    condition: always()
  
  - script: |
      python scripts/analyze_vulnerabilities.py
    displayName: 'Analyze Vulnerability Report'
    condition: always()
```

---

## Integration Points

- **Build Pipeline:** Integrate SBOM generation and artifact signing into CI/CD
- **Package Registry:** Store artifacts with signatures and SBOMs
- **Artifact Repository:** Track provenance and audit trails
- **Compliance System:** Report on SLSA level compliance

---

## Success Criteria

✅ **Artifact Signing:**
- All release artifacts signed with key pair
- Signatures verifiable against transparency log
- Zero unsigned releases in production

✅ **SBOM Generation:**
- SBOM generated for every release
- SBOM includes all direct and transitive dependencies
- Vulnerability scanning integrated with SBOM

✅ **SLSA Compliance:**
- Level 2+: Automated builds with provenance
- Level 3+: Hermetic reproducible builds
- Build logs immutable and signed

✅ **Dependency Management:**
- All dependencies scanned for vulnerabilities
- Critical vulnerabilities blocked
- Dependency updates tracked and tested

---

## Output

- **Signed Artifact Manifest** — list of signed artifacts with signature references in the Rekor transparency log
- **SBOM Report** — software bill of materials in CycloneDX or SPDX format covering all direct and transitive dependencies
- **SLSA Compliance Assessment** — current SLSA level achieved, gaps to next level, and remediation steps
- **Vulnerability Scan Summary** — dependency CVEs by severity with fix availability and SLA-based remediation timeline
- **Build Provenance Attestation** — in-toto provenance document linking artifact to build platform and source commit

## References(https://slsa.dev/)
- [Sigstore Project](https://www.sigstore.dev/)
- [SBOM/CycloneDX](https://cyclonedx.org/)
- [SPDX Specification](https://spdx.dev/)
- [in-toto Provenance](https://in-toto.io/)

## Model

**Recommended:** claude-sonnet-4.6
**Rationale:** Supply chain risk analysis, dependency trust evaluation, and SBOM validation require structured reasoning
**Minimum:** gpt-5.4-mini

## Governance

This agent operates under the basecoat governance framework.

- **Issue-first**: Do not make code changes without a logged GitHub issue.
- **PRs only**: Never commit directly to `main`. Open a PR, self-approve if needed.
- **No secrets**: Never commit credentials, tokens, API keys, or sensitive data.
- **Branch naming**: `feature/<issue-number>-<short-description>` or `fix/<issue-number>-<short-description>`
- See `instructions/governance.instructions.md` for the full governance reference.
