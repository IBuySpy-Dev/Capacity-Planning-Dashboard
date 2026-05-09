---
name: environment-bootstrap
description: Automated setup for OIDC federation, state storage, Key Vault, and environment promotion in Azure CI/CD pipelines. Now includes Fabric workspace service principal access automation.
context: fork
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Infrastructure & DevOps"
  tags: ["azure", "oidc", "terraform", "bicep", "keyvault", "fabric", "aks"]
allowed-tools: ["bash", "azure-cli", "terraform", "kubectl", "curl"]
---

# Environment Bootstrap Skill

## Overview

The Environment Bootstrap Skill provides a complete setup for establishing secure, reproducible Azure environments with federated identity credentials for CI/CD, centralized state management, secrets handling, and multi-environment promotion workflows.

## Key Capabilities

- **OIDC Federation**: Configure workload identity federation for GitHub Actions without storing long-lived credentials
- **State Storage**: Set up Terraform and Bicep deployment state backends with encryption and access controls
- **Key Vault Provisioning**: Automate Azure Key Vault creation with RBAC policies and secret management
- **GitHub Actions Secrets**: Integrate environment secrets with GitHub Actions for CI/CD workflows
- **Environment Promotion**: Establish dev→staging→prod promotion pipelines with gating controls
- **Workload Identity**: Enable service principals with federated identity for pod-level authentication

## OIDC Federation Setup for CI/CD

See \eferences/oidc-federation.md\ for complete OIDC federation setup instructions including:
- Creating Entra ID applications
- Configuring federated credentials
- Assigning RBAC roles
- GitHub Actions OIDC token exchange
- Multi-environment federation
- Troubleshooting guide

## Terraform and Bicep State Storage Configuration

See \eferences/terraform-bicep-state-storage.md\ for state storage setup including:
- Storage account creation and configuration
- Blob container and backend setup
- Bicep templates for state management
- Versioning and recovery

## Azure Key Vault Provisioning

See \eferences/azure-keyvault-provisioning.md\ for Key Vault setup including:
- Key Vault creation and RBAC configuration
- Secret management for CI/CD
- Bicep templates for infrastructure-as-code

## GitHub Actions Secrets Configuration

See \eferences/github-actions-secrets.md\ for GitHub Actions integration including:
- Workflow configuration with Azure credentials
- Retrieving secrets from Key Vault
- Setting GitHub repository secrets

## Environment Promotion

See \eferences/environment-promotion.md\ for multi-environment promotion including:
- Dev→Staging→Prod promotion strategies
- Approval gates and manual controls
- GitHub Environments configuration
- Deployment workflows

## Workload Identity Federation

See \eferences/workload-identity-federation.md\ for pod-level authentication including:
- AKS prerequisites and setup
- Federated credentials for Kubernetes pods
- Service account configuration
- Pod deployment with workload identity

## Troubleshooting

See \eferences/troubleshooting.md\ for common issues and solutions including:
- OIDC token exchange failures
- State storage access issues
- Key Vault access denied errors
- Diagnostic commands

## Microsoft Fabric Workspace Service Principal Access

See \eferences/fabric-workspace-access.md\ for Fabric workspace automation including:
- Creating service principals for Fabric access
- Assigning workspace roles via REST API
- Storing credentials in Key Vault
- Bicep templates for role assignment
- GitHub Actions automation

## References

- **Azure Landing Zones**: Enterprise-scale deployment patterns
- **GitHub Actions**: CI/CD automation platform
- **Azure AD / Entra ID**: Identity and access management
- **Microsoft Fabric**: Analytics and BI platform
