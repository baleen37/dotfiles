#!/usr/bin/env node

/**
 * ABOUTME: Validates Claude agent markdown template structure
 * ABOUTME: Checks YAML frontmatter and markdown format compliance
 */

const fs = require('fs');
const path = require('path');

// Colors for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

class AgentValidator {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.agentsDir = path.join(__dirname, '../modules/shared/config/claude/agents');
  }

  log(message, color = colors.reset) {
    console.log(`${color}${message}${colors.reset}`);
  }

  error(message) {
    this.errors.push(message);
    this.log(`❌ ${message}`, colors.red);
  }

  warning(message) {
    this.warnings.push(message);
    this.log(`⚠️  ${message}`, colors.yellow);
  }

  success(message) {
    this.log(`✅ ${message}`, colors.green);
  }

  info(message) {
    this.log(`ℹ️  ${message}`, colors.blue);
  }

  validateFile(filePath) {
    const fileName = path.basename(filePath);
    const fileContent = fs.readFileSync(filePath, 'utf8');

    this.info(`Validating ${fileName}...`);

    // Skip README.md
    if (fileName === 'README.md') {
      this.info(`Skipping ${fileName}`);
      return;
    }

    // Extract YAML frontmatter - handle files that start with header
    let cleanContent = fileContent;
    if (fileContent.startsWith('--- ')) {
      // Remove the file header line if present
      cleanContent = fileContent.split('\n').slice(2).join('\n');
    }

    const frontmatterMatch = cleanContent.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatterMatch) {
      this.error(`${fileName}: Missing YAML frontmatter`);
      return;
    }

    let frontmatter;
    try {
      // Simple YAML parser for our basic needs
      const yamlContent = frontmatterMatch[1];
      frontmatter = this.parseSimpleYaml(yamlContent);
    } catch (error) {
      this.error(`${fileName}: Invalid YAML frontmatter: ${error.message}`);
      return;
    }

    // Check markdown template compliance
    this.validateMarkdownTemplate(fileName, fileContent, frontmatter);
  }

  parseSimpleYaml(yamlContent) {
    const result = {};
    const lines = yamlContent.split('\n');

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;

      const colonIndex = trimmed.indexOf(':');
      if (colonIndex === -1) continue;

      const key = trimmed.substring(0, colonIndex).trim();
      const value = trimmed.substring(colonIndex + 1).trim();

      result[key] = value;
    }

    return result;
  }

  validateMarkdownTemplate(fileName, content, frontmatter) {
    // Check YAML frontmatter structure
    if (!frontmatter.name) {
      this.error(`${fileName}: Missing 'name' field in YAML frontmatter`);
    }

    if (!frontmatter.description) {
      this.error(`${fileName}: Missing 'description' field in YAML frontmatter`);
    }

    // Check markdown structure
    const afterFrontmatter = content.split('---')[2];
    if (!afterFrontmatter || !afterFrontmatter.includes('You are')) {
      this.error(`${fileName}: Missing "You are..." persona statement`);
    }

    if (!content.includes('#')) {
      this.error(`${fileName}: No markdown headers found - templates should have structured sections`);
    }
  }

  validate() {
    this.log(`\n${colors.bold}🔍 Validating Claude Agent Templates${colors.reset}`);
    this.log(`Agent directory: ${this.agentsDir}`);

    if (!fs.existsSync(this.agentsDir)) {
      this.error(`Agents directory not found: ${this.agentsDir}`);
      return false;
    }

    const files = fs.readdirSync(this.agentsDir)
      .filter(f => f.endsWith('.md'))
      .map(f => path.join(this.agentsDir, f));

    this.log(`Found ${files.length} agent files\n`);

    // Validate each file
    files.forEach(file => this.validateFile(file));

    // Generate report
    this.generateReport();

    return this.errors.length === 0;
  }

  generateReport() {
    this.log(`\n${colors.bold}📊 Validation Report${colors.reset}`);
    this.log(`Errors: ${this.errors.length}`);
    this.log(`Warnings: ${this.warnings.length}`);

    if (this.errors.length === 0 && this.warnings.length === 0) {
      this.success('All agent templates are valid! 🎉');
    } else if (this.errors.length === 0) {
      this.success('Templates passed with warnings 🎉');
      this.log(`\n${colors.yellow}Note: ${this.warnings.length} warnings found${colors.reset}`);
    } else {
      this.log(`\n${colors.red}Template validation failed${colors.reset}`);
    }

    // All validation output is shown in console
    // No file generation needed for pre-commit hooks
  }
}

// Run validation if called directly
if (require.main === module) {
  const validator = new AgentValidator();
  const success = validator.validate();
  process.exit(success ? 0 : 1);
}

module.exports = AgentValidator;
