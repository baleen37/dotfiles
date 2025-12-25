# Skill Location Strategy

## Official Standard (Anthropic)

**Personal Skills**: `~/.claude/skills/`
**Plugin Skills**: `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/skills/`

**Project Skills**: ❌ NOT officially supported by Claude Code

## This Project's Implementation

### Source Location
```
/Users/jito.hello/dotfiles/users/shared/.config/claude/skills/
└── setup-precommit-and-ci/
    ├── SKILL.md
    ├── setup-branch-protection.sh
    ├── ci-workflow-template.yml
    ├── precommit-config-template.yml
    └── docs/
```

**Why here?**
- Git version control in dotfiles repository
- Shared across multiple machines via Nix
- Team collaboration through git

### Runtime Location (via Nix)
```
~/.claude/skills/
└── setup-precommit-and-ci/ -> /nix/store/.../setup-precommit-and-ci/
```

**How it works**:
1. Nix home-manager reads dotfiles configuration
2. Copies files to Nix store (immutable)
3. Creates symlinks in `~/.claude/skills/`
4. Claude Code loads from `~/.claude/skills/` (follows symlinks)

### Verification

```bash
# Check symlink
$ file ~/.claude/skills/setup-precommit-and-ci/SKILL.md
symbolic link to /nix/store/.../SKILL.md

# Verify it works
$ /skill setup-precommit-and-ci
✓ Skill loads successfully
```

## Why NOT `.claude/skills/` in Project?

### Research Findings

**Agent A (Correct)**:
- Claude Code does NOT officially support project skills
- Only OpenCode supports `.opencode/skills/`
- Codex does NOT support project skills

**Agent B (Found Bug)**:
- Issue #10061: Subagents ignore project skills
- Even if `.claude/skills/` exists, it doesn't work reliably

### Attempted Workarounds

**❌ Doesn't work**:
```
/Users/jito.hello/dotfiles/.claude/skills/
└── setup-precommit-and-ci/
```
Claude Code won't find this.

**✅ Works (our approach)**:
```
1. Source: dotfiles/users/shared/.config/claude/skills/
2. Nix: Copy to /nix/store/
3. Symlink: ~/.claude/skills/ -> /nix/store/
4. Claude: Loads from ~/.claude/skills/
```

## Alternative Approaches (Not Used)

### Manual Symlink
```bash
ln -s /Users/jito.hello/dotfiles/users/shared/.config/claude/skills/setup-precommit-and-ci \
      ~/.claude/skills/
```
**Pros**: Simple, direct
**Cons**: Manual per machine, not declarative

### Direct Git Clone
```bash
cd ~/.claude/skills
git clone https://github.com/team/skills.git .
```
**Pros**: Standard git workflow
**Cons**: Mixes personal and shared skills, no Nix benefits

### Nix Home-Manager (Current)
```nix
home.file.".claude/skills" = {
  source = ./users/shared/.config/claude/skills;
  recursive = true;
};
```
**Pros**: Declarative, reproducible, atomic updates
**Cons**: Requires Nix, indirect path

## Priority System

When same skill name exists:

1. **Personal** (`~/.claude/skills/my-skill`)
2. **Plugin** (`~/.claude/plugins/.../my-skill`)

**Override plugin skill**:
```bash
# Plugin version exists: superpowers:brainstorming
# Create personal override
cp -r ~/.claude/plugins/.../brainstorming ~/.claude/skills/
vim ~/.claude/skills/brainstorming/SKILL.md

# Now loads personal version by default
/skill brainstorming  # Personal
/skill superpowers:brainstorming  # Plugin (explicit)
```

## Best Practices

### For Personal Skills
- Store in `~/.claude/skills/`
- Use this dotfiles approach if managing with Nix
- Version control recommended (git)

### For Team Sharing
Since Claude Code doesn't support project skills:

**Option 1 - Shared Git Repo**:
```bash
# Team repo: https://github.com/team/claude-skills
git clone https://github.com/team/claude-skills ~/.claude/skills-team
ln -s ~/.claude/skills-team/* ~/.claude/skills/
```

**Option 2 - Dotfiles (This Approach)**:
```bash
# Each team member clones dotfiles
git clone https://github.com/team/dotfiles
# Nix automatically symlinks to ~/.claude/skills/
```

**Option 3 - Plugin Marketplace**:
- Publish to marketplace
- Team installs via `/plugin install`
- Requires plugin development overhead

## Competitive Research Summary

**Both agents agreed**:
- ✅ `~/.claude/skills/` is the official location
- ✅ Symlinks work (Read tool follows them)
- ✅ Personal > Plugin priority

**Key disagreement**:
- **Agent A**: Project skills NOT supported (correct)
- **Agent B**: Project skills supported but buggy (partially correct)

**Truth**: Claude Code doesn't officially support `.claude/skills/` in projects, and even attempts to use it hit bugs (Issue #10061).

## Conclusion

**Current location is optimal**:
- ✅ Follows Anthropic standard (`~/.claude/skills/`)
- ✅ Git version controlled (source in dotfiles)
- ✅ Nix-managed (reproducible)
- ✅ Symlinks work (verified)
- ✅ Team shareable (via dotfiles)

**No changes needed** - structure already compliant with official standards.
