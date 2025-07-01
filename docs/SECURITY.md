# Security Guide

> **Comprehensive security guidelines and best practices for the Nix dotfiles system**

This guide outlines security considerations, best practices, and threat mitigation strategies for maintaining a secure dotfiles environment.

## Security Architecture

### Core Security Principles

1. **Least Privilege**: Minimal permissions for system operations
2. **Defense in Depth**: Multiple layers of security controls
3. **Transparency**: All configurations and dependencies visible and auditable
4. **Immutability**: Read-only configurations prevent unauthorized modification
5. **Reproducibility**: Deterministic builds enable security verification

### Threat Model

**Assets Protected**:
- System configuration integrity
- User credentials and SSH keys
- Development environment consistency
- Build and deployment pipeline

**Threat Vectors**:
- Malicious package injection
- Configuration tampering
- Privilege escalation
- Supply chain attacks
- Credential exposure

## Package and Dependency Security

### Nix Package Verification

**Package Source Validation**:
```bash
# Verify package integrity
nix store verify --all

# Check package signatures
nix store verify /nix/store/...-package

# Audit package sources
nix show-derivation nixpkgs#package-name
```

**Trusted Sources Policy**:
- Primary: Official nixpkgs repository
- Secondary: Trusted overlays with explicit review
- Prohibited: Arbitrary URLs or unverified sources

### Overlay Security

**Overlay Review Process**:
1. **Source Verification**: All overlays must be from trusted repositories
2. **Code Review**: Custom overlays require security review
3. **Minimal Scope**: Overlays limited to specific, necessary modifications
4. **Documentation**: All overlays documented with security rationale

**Security Guidelines** (based on `docs/overlay-security.md`):

```nix
# Good: Minimal, specific overlay
self: super: {
  my-tool = super.my-tool.overrideAttrs (old: {
    version = "1.2.3";
    src = super.fetchurl {
      url = "https://trusted-source.com/release-1.2.3.tar.gz";
      sha256 = "known-good-hash";
    };
  });
}

# Bad: Overly broad overlay with untrusted sources
self: super: {
  # Multiple packages from various sources
  # Unknown or missing integrity hashes
  # Broad system modifications
}
```

## Access Control and Permissions

### Sudo and Privilege Management

**build-switch Security**:
- Early permission acquisition minimizes privilege window
- Automatic permission cleanup after operations
- Session isolation prevents privilege persistence
- Logging of all privileged operations

```bash
# Secure privilege handling
nix run --impure .#build-switch
# → Explains why sudo is needed
# → Requests password once at start
# → Maintains session only during operation
# → Cleans up automatically
```

**Manual Sudo Guidelines**:
```bash
# Correct: Preserve environment variables
sudo -E USER=$USER command

# Incorrect: Running as root without context
sudo command

# Best: Use automated build-switch
nix run --impure .#build-switch
```

### SSH Key Management

**Key Generation Security**:
```bash
# Generate secure SSH keys
nix run .#create-keys

# Key specifications:
# - Ed25519 algorithm (recommended)
# - 4096-bit RSA (legacy compatibility)
# - Passphrase protection required
```

**Key Storage and Access**:
- Keys stored in `~/.ssh/` with proper permissions (600)
- Public keys copyable via `nix run .#copy-keys`
- Private keys never committed or transmitted
- Key rotation recommended annually

### File Permissions

**Configuration File Security**:
- System files: Read-only via Nix store
- User configurations: Managed by Home Manager
- Secrets: Excluded via `.gitignore` and careful handling
- Logs: Restricted access, automatic rotation

## Secrets Management

### Credential Handling

**Never Commit**:
- API keys, tokens, passwords
- SSH private keys
- Service account credentials
- Personal identifiable information

**Best Practices**:
```bash
# Use environment variables
export API_KEY="$(cat ~/.secrets/api-key)"

# Use external secret management
# - 1Password CLI integration
# - macOS Keychain access
# - Pass (password-store)

# Verify no secrets in history
git log --all --grep="password\|key\|secret" --oneline
```

### Age Encryption Integration

**For Sensitive Configuration**:
```nix
# Use age for encrypted secrets
age.secrets.example = {
  file = ../secrets/example.age;
  owner = "username";
  group = "wheel";
};
```

**Encryption Workflow**:
```bash
# Encrypt sensitive files
age -r public-key -o secret.age secret.txt

# Store only encrypted versions in repository
git add secret.age
git add -N secret.txt  # Never add the plaintext
```

## Build and CI Security

### Build Environment

**Isolation Measures**:
- Builds run in isolated Nix sandboxes
- Network access restricted during builds
- Temporary directories cleaned automatically
- No persistent state between builds

**Verification Steps**:
```bash
# Pre-commit security checks
make lint                    # Code quality and security linting
nix flake check --impure     # Flake structure validation
make build                   # Full build verification

# CI pipeline replication
./scripts/test-all-local     # Complete local testing
```

### CI/CD Pipeline Security

**GitHub Actions Security**:
- Minimal required permissions for workflows
- No secrets in logs or outputs
- Dependency pinning for action versions
- Regular security updates for actions

**Build Verification**:
- All builds reproducible and deterministic
- No arbitrary code execution
- Package integrity verification
- Audit trail for all changes

## System Hardening

### macOS Security

**System Integrity Protection**:
- Maintain SIP enabled
- Use approved modification methods only
- Document all system-level changes
- Regular security update application

**Application Security**:
```nix
# Homebrew casks from trusted sources only
homebrew.casks = [
  "firefox"           # Verified source
  "visual-studio-code" # Official Microsoft distribution
  # Never: untrusted or modified applications
];
```

### NixOS Security

**System Configuration**:
```nix
{
  # Enable firewall
  networking.firewall.enable = true;
  
  # Disable unnecessary services
  services.unnecessary-service.enable = false;
  
  # Configure fail2ban
  services.fail2ban.enable = true;
  
  # Regular security updates
  system.autoUpgrade.enable = true;
}
```

## Monitoring and Auditing

### Security Monitoring

**Regular Checks**:
```bash
# Package vulnerability scanning
nix-env --query --available --attr-path nixos.vulnix

# System integrity verification
nix store verify --all

# Configuration drift detection
make build && make test
```

**Audit Procedures**:
1. **Monthly**: Review access logs and system changes
2. **Quarterly**: Full security configuration review
3. **Annually**: Threat model update and key rotation
4. **As needed**: Incident response and remediation

### Logging and Alerting

**Security Events**:
- Failed sudo attempts
- SSH authentication failures
- Unauthorized configuration changes
- Build failures or anomalies

**Log Management**:
- Centralized logging for security events
- Log retention policies
- Automated alerting for critical events
- Regular log review procedures

## Incident Response

### Security Incident Procedures

**Detection and Assessment**:
1. Identify the nature and scope of the incident
2. Determine affected systems and data
3. Assess potential impact and damage
4. Document all findings and actions

**Containment and Recovery**:
```bash
# Immediate isolation
sudo systemctl stop networking  # NixOS
sudo dscacheutil -flushcache   # macOS

# Rollback to known good state
sudo nixos-rebuild switch --rollback  # NixOS
nix run .#rollback                     # macOS

# Verify system integrity
nix store verify --all
make build && make test
```

**Communication and Documentation**:
- Internal incident notification
- External disclosure if required
- Lessons learned documentation
- Process improvement recommendations

### Recovery Procedures

**System Recovery**:
```bash
# Clean rebuild from trusted sources
nix store gc
nix flake update
make build
make test

# Verify configuration integrity
git status
git log --oneline -10
```

**Credential Rotation**:
```bash
# Rotate SSH keys
nix run .#create-keys

# Update service credentials
# - API tokens
# - Database passwords
# - Service account keys
```

## Compliance and Governance

### Security Policies

**Access Control Policy**:
- Regular access review (quarterly)
- Principle of least privilege
- Multi-factor authentication where possible
- Account lifecycle management

**Change Management**:
- All changes via pull requests
- Required security review for sensitive changes
- Automated testing and validation
- Rollback procedures documented and tested

### Regulatory Considerations

**Data Protection**:
- No personal data in configurations
- Secure handling of development credentials
- Regular data retention policy review
- Privacy by design principles

**Audit Requirements**:
- Comprehensive logging of system changes
- Access trail maintenance
- Regular compliance verification
- External audit facilitation

## Security Checklist

### Daily Operations
- [ ] Use `build-switch` for system changes
- [ ] Verify USER environment variable set
- [ ] Check for security updates
- [ ] Review uncommitted changes

### Weekly Reviews
- [ ] Run comprehensive test suite
- [ ] Review access logs
- [ ] Check for dependency updates
- [ ] Verify backup integrity

### Monthly Tasks
- [ ] Security configuration review
- [ ] Vulnerability scanning
- [ ] Access control audit
- [ ] Incident response plan review

### Annual Activities
- [ ] Threat model update
- [ ] Security training refresh
- [ ] Penetration testing
- [ ] Policy and procedure review

---

**Remember**: Security is a continuous process. Regular review and updates of these practices ensure ongoing protection of your development environment and sensitive data.