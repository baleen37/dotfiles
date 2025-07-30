#!/usr/bin/env node

/**
 * ABOUTME: Validates Claude agent markdown files against schema and conventions
 * ABOUTME: Checks YAML frontmatter, naming conventions, and content structure
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Colors for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

class AgentValidator {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.agentsDir = path.join(__dirname, '../modules/shared/config/claude/agents');
    this.schemaPath = path.join(__dirname, 'claude-agent-schema.json');
    this.schema = this.loadSchema();
  }

  loadSchema() {
    try {
      const schemaContent = fs.readFileSync(this.schemaPath, 'utf8');
      return JSON.parse(schemaContent);
    } catch (error) {
      this.error(`Failed to load schema from ${this.schemaPath}: ${error.message}`);
      process.exit(1);
    }
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

    // Validate against schema
    this.validateAgainstSchema(fileName, frontmatter);

    // Additional validations
    this.validateFileNaming(fileName, frontmatter);
    this.validateContent(fileName, fileContent);
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

  validateAgainstSchema(fileName, frontmatter) {
    // Manual schema validation (simple implementation)
    const { name, description } = frontmatter;

    // Check required fields
    if (!name) {
      this.error(`${fileName}: Missing required field 'name'`);
    }

    if (!description) {
      this.error(`${fileName}: Missing required field 'description'`);
    }

    // Validate name pattern
    if (name && !/^[a-z0-9-]+$/.test(name)) {
      this.error(`${fileName}: Name '${name}' must be lowercase kebab-case (letters, numbers, hyphens only)`);
    }

    // Validate description length
    if (description) {
      if (description.length < 10) {
        this.error(`${fileName}: Description must be at least 10 characters`);
      }
      if (description.length > 500) {
        this.error(`${fileName}: Description must be no more than 500 characters`);
      }
    }
  }

  validateFileNaming(fileName, frontmatter) {
    const expectedFileName = `${frontmatter.name}.md`;
    if (fileName !== expectedFileName) {
      this.error(`${fileName}: Filename should be '${expectedFileName}' to match name field`);
    }
  }

  validateContent(fileName, content) {
    // Check for "You are" opening statement
    const afterFrontmatter = content.split('---')[2];
    if (afterFrontmatter && !afterFrontmatter.includes('You are')) {
      this.warning(`${fileName}: Content should start with "You are" statement`);
    }

    // Check for basic markdown structure
    if (!content.includes('#')) {
      this.warning(`${fileName}: No markdown headers found`);
    }
  }

  checkForDuplicateNames() {
    const names = new Set();
    const files = fs.readdirSync(this.agentsDir).filter(f => f.endsWith('.md') && f !== 'README.md');

    for (const file of files) {
      const filePath = path.join(this.agentsDir, file);
      const content = fs.readFileSync(filePath, 'utf8');

      // Handle files that start with header
      let cleanContent = content;
      if (content.startsWith('--- ')) {
        cleanContent = content.split('\n').slice(2).join('\n');
      }

      const frontmatterMatch = cleanContent.match(/^---\n([\s\S]*?)\n---/);

      if (frontmatterMatch) {
        try {
          const frontmatter = this.parseSimpleYaml(frontmatterMatch[1]);
          if (frontmatter.name) {
            if (names.has(frontmatter.name)) {
              this.error(`Duplicate agent name '${frontmatter.name}' found in ${file}`);
            } else {
              names.add(frontmatter.name);
            }
          }
        } catch (error) {
          // Already handled in validateFile
        }
      }
    }
  }

  validate() {
    this.log(`\n${colors.bold}🔍 Validating Claude Agents${colors.reset}`);
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

    // Check for duplicate names
    this.checkForDuplicateNames();

    // Generate report
    this.generateReport();

    return this.errors.length === 0;
  }

  generateReport() {
    this.log(`\n${colors.bold}📊 Validation Report${colors.reset}`);
    this.log(`Errors: ${this.errors.length}`);
    this.log(`Warnings: ${this.warnings.length}`);

    if (this.errors.length === 0 && this.warnings.length === 0) {
      this.success('All agents passed validation! 🎉');
    } else if (this.errors.length === 0) {
      this.success('Validation passed with warnings 🎉');
      this.log(`\n${colors.yellow}Note: ${this.warnings.length} warnings found${colors.reset}`);
    } else {
      this.log(`\n${colors.red}Validation failed${colors.reset}`);
    }

    // Write detailed report file
    const reportPath = path.join(__dirname, '../validation-report.txt');
    const reportContent = [
      '# Claude Agents Validation Report',
      `Generated: ${new Date().toISOString()}`,
      '',
      '## Summary',
      `Errors: ${this.errors.length}`,
      `Warnings: ${this.warnings.length}`,
      '',
      '## Errors',
      ...this.errors.map(e => `- ${e}`),
      '',
      '## Warnings',
      ...this.warnings.map(w => `- ${w}`)
    ].join('\n');

    fs.writeFileSync(reportPath, reportContent);
    this.info(`Detailed report written to: ${reportPath}`);
  }
}

// Run validation if called directly
if (require.main === module) {
  const validator = new AgentValidator();
  const success = validator.validate();
  process.exit(success ? 0 : 1);
}

module.exports = AgentValidator;
