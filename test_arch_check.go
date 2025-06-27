package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// ArchRule represents an architectural rule
type ArchRule struct {
	Name        string
	Description string
	Checker     func(pkg *Package) []Violation
}

// Package represents a Go package with its metadata
type Package struct {
	Path      string
	Dir       string
	Files     []*ast.File
	Imports   []string
	IsCore    bool
	IsPorts   bool
	IsAdapter bool
}

// Violation represents an architectural rule violation
type Violation struct {
	Package string
	File    string
	Rule    string
	Message string
}

func main() {
	fmt.Println("🏗️  Architecture Analysis for ssulmeta-go")
	fmt.Println("==========================================")

	// Define architectural rules
	rules := []ArchRule{
		{
			Name:        "core-no-external-deps",
			Description: "Core packages should not import external libraries except standard library",
			Checker:     checkCoreExternalDeps,
		},
		{
			Name:        "core-no-adapters",
			Description: "Core packages should not import adapter packages",
			Checker:     checkCoreAdapterDeps,
		},
		{
			Name:        "proper-dependency-direction",
			Description: "Dependencies should flow: adapters -> ports -> core",
			Checker:     checkDependencyDirection,
		},
	}

	// Analyze packages
	packages, err := analyzePackages("../../../../../internal")
	if err != nil {
		fmt.Printf("❌ Error analyzing packages: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("📦 Found %d packages to analyze\n\n", len(packages))

	// Run checks
	allViolations := []Violation{}
	for _, rule := range rules {
		fmt.Printf("🔍 Checking rule: %s\n", rule.Name)
		fmt.Printf("   %s\n", rule.Description)

		ruleViolations := []Violation{}
		for _, pkg := range packages {
			violations := rule.Checker(pkg)
			ruleViolations = append(ruleViolations, violations...)
		}

		if len(ruleViolations) == 0 {
			fmt.Printf("   ✅ PASS - No violations found\n\n")
		} else {
			fmt.Printf("   ❌ FAIL - %d violation(s) found:\n", len(ruleViolations))
			for _, v := range ruleViolations {
				fmt.Printf("      - %s: %s\n", v.Package, v.Message)
			}
			fmt.Println()
		}

		allViolations = append(allViolations, ruleViolations...)
	}

	// Summary
	fmt.Println("📊 Analysis Summary")
	fmt.Println("==================")
	if len(allViolations) == 0 {
		fmt.Println("✅ All architectural rules are satisfied!")
		fmt.Println("🎉 Your hexagonal architecture is properly implemented.")
	} else {
		fmt.Printf("❌ Found %d total violations\n", len(allViolations))
		fmt.Println("\n📋 Detailed violations:")
		for i, v := range allViolations {
			fmt.Printf("%d. [%s] %s\n   File: %s\n   Issue: %s\n\n",
				i+1, v.Rule, v.Package, v.File, v.Message)
		}
		os.Exit(1)
	}
}

func analyzePackages(rootDir string) ([]*Package, error) {
	var packages []*Package

	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() {
			return nil
		}

		// Skip test directories and hidden directories
		if strings.Contains(path, "test") || strings.HasPrefix(info.Name(), ".") {
			return filepath.SkipDir
		}

		// Check if this directory contains Go files
		files, err := filepath.Glob(filepath.Join(path, "*.go"))
		if err != nil {
			return err
		}

		// Filter out test files
		var sourceFiles []string
		for _, file := range files {
			if !strings.HasSuffix(file, "_test.go") {
				sourceFiles = append(sourceFiles, file)
			}
		}

		if len(sourceFiles) == 0 {
			return nil
		}

		pkg, err := analyzePackage(path, sourceFiles)
		if err != nil {
			fmt.Printf("Warning: Error analyzing package %s: %v\n", path, err)
			return nil
		}

		packages = append(packages, pkg)
		return nil
	})

	return packages, err
}

func analyzePackage(dir string, files []string) (*Package, error) {
	fset := token.NewFileSet()
	var astFiles []*ast.File
	var imports []string

	for _, filename := range files {
		src, err := os.Open(filename)
		if err != nil {
			return nil, err
		}
		defer func() {
			if err := src.Close(); err != nil {
				log.Printf("failed to close file %s: %v", filename, err)
			}
		}()

		file, err := parser.ParseFile(fset, filename, src, parser.ParseComments)
		if err != nil {
			return nil, err
		}

		astFiles = append(astFiles, file)

		// Extract imports
		for _, imp := range file.Imports {
			importPath := strings.Trim(imp.Path.Value, "\"")
			imports = append(imports, importPath)
		}
	}

	// Determine package type
	isCore := strings.Contains(dir, "/core")
	isPorts := strings.Contains(dir, "/ports")
	isAdapter := strings.Contains(dir, "/adapters")

	return &Package{
		Path:      dir,
		Dir:       dir,
		Files:     astFiles,
		Imports:   imports,
		IsCore:    isCore,
		IsPorts:   isPorts,
		IsAdapter: isAdapter,
	}, nil
}

func checkCoreExternalDeps(pkg *Package) []Violation {
	if !pkg.IsCore {
		return nil
	}

	var violations []Violation
	standardLibRegex := regexp.MustCompile(`^[a-z]+(/[a-z]+)*$`)
	extendedStdRegex := regexp.MustCompile(`^golang\.org/x/`)

	for _, imp := range pkg.Imports {
		// Allow standard library and golang.org/x extensions
		if standardLibRegex.MatchString(imp) || extendedStdRegex.MatchString(imp) {
			continue
		}

		// Allow internal project imports
		if strings.HasPrefix(imp, "ssulmeta-go/") {
			continue
		}

		violations = append(violations, Violation{
			Package: pkg.Path,
			File:    "multiple files",
			Rule:    "core-no-external-deps",
			Message: fmt.Sprintf("Core package imports external dependency: %s", imp),
		})
	}

	return violations
}

func checkCoreAdapterDeps(pkg *Package) []Violation {
	if !pkg.IsCore {
		return nil
	}

	var violations []Violation
	for _, imp := range pkg.Imports {
		if strings.Contains(imp, "/adapters") {
			violations = append(violations, Violation{
				Package: pkg.Path,
				File:    "multiple files",
				Rule:    "core-no-adapters",
				Message: fmt.Sprintf("Core package imports adapter: %s", imp),
			})
		}
	}

	return violations
}

func checkDependencyDirection(pkg *Package) []Violation {
	var violations []Violation

	if pkg.IsPorts {
		// Ports should not import adapters
		for _, imp := range pkg.Imports {
			if strings.Contains(imp, "/adapters") {
				violations = append(violations, Violation{
					Package: pkg.Path,
					File:    "multiple files",
					Rule:    "proper-dependency-direction",
					Message: fmt.Sprintf("Ports package imports adapter: %s", imp),
				})
			}
		}
	}

	// Additional checks can be added here for other dependency directions

	return violations
}
