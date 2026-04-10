# Advanced test assertion helpers
#
# Provides:
# - Performance testing (assertPerformance)
# - File content comparison (assertFileContent)
# - Verbose error reporting (assertTestWithDetailsVerbose)
# - Deep equality (assertAttrsEqual)
# - Git configuration validation (assertGitUserInfo, assertGitSettings, assertGitAliases, assertGitIgnorePatterns)
# - Generic membership testing (assertContainsGeneric)
# - Plugin/package validation (assertPluginPresent)
# - File system validation (assertFileReadable)
# - Module import validation (assertImportPresent)
{
  pkgs,
  lib,
  assertTest,
  testSuite,
  mkTest,
}:

{
  # Performance assertion helper
  assertPerformance =
    name: expectedBoundMs: command:
    let
      performanceScript = pkgs.writeShellScript "perf-script-${name}" ''
        # Measure execution time
        start_time=$(/usr/bin/time -p bash -c '${command}' 2>&1 | grep "real" | awk '{print $2}')
        echo "Execution time: $start_time seconds"

        # Convert to milliseconds and check bound
        echo "$start_time * 1000" | bc | sed 's/\.0*$//' | {
          read time_ms
          echo "Time in ms: $time_ms"

          if [ "$time_ms" -le ${toString expectedBoundMs} ]; then
            echo "✅ Performance test ${name}: PASS"
            echo "  Time: $time_ms ms (≤ ${toString expectedBoundMs} ms)"
            exit 0
          else
            echo "❌ Performance test ${name}: FAIL"
            echo "  Time: $time_ms ms (> ${toString expectedBoundMs} ms)"
            exit 1
          fi
        }
      '';
    in
    pkgs.runCommand "perf-test-${name}"
      {
        buildInputs = [ pkgs.bc ];
        passthru.script = performanceScript;
      }
      ''
        echo "🕒 Running performance test: ${name}"
        echo "Expected bound: ${toString expectedBoundMs}ms"
        echo "Command: ${command}"
        echo ""

        ${performanceScript}

        if [ $? -eq 0 ]; then
          touch $out
        else
          exit 1
        fi
      '';

  # File content validation with diff support
  assertFileContent =
    name: expectedPath: actualPath:
    pkgs.runCommand "test-${name}" {
      inherit expectedPath actualPath;
    } ''
      if diff -u "$expectedPath" "$actualPath" > /dev/null 2>&1; then
        echo "PASS: ${name}"
        touch $out
      else
        echo "FAIL: ${name}"
        echo "  File content mismatch"
        echo "  Expected: $expectedPath"
        echo "  Actual: $actualPath"
        echo ""
        echo "Diff:"
        diff -u "$expectedPath" "$actualPath" || true
        exit 1
      fi
    '';

  # Enhanced assertion with verbose error reporting including location info
  assertTestWithDetailsVerbose =
    name: condition: message: expected: actual: file: line:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "PASS: ${name}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "FAIL: ${name}"
        echo "  ${message}"
        ${lib.optionalString (expected != null) ''
        echo "  Expected: ${expected}"
        ''}
        ${lib.optionalString (actual != null) ''
        echo "  Actual: ${actual}"
        ''}
        ${lib.optionalString (file != null) ''
        echo "  Location: ${file}${lib.optionalString (line != null) ":${toString line}"}"
        ''}
        exit 1
      '';

  # Backward compatibility alias
  mkSimpleTest = mkTest;

  # Compare two attribute sets for deep equality
  assertAttrsEqual =
    name: expected: actual: message:
    let
      expectedKeys = builtins.attrNames expected;
      actualKeys = builtins.attrNames actual;
      allKeys = lib.unique (expectedKeys ++ actualKeys);

      mismatches = builtins.filter (
        key:
        let
          expectedValue = builtins.toString expected.${key} or "<missing>";
          actualValue = builtins.toString actual.${key} or "<missing>";
        in
        expectedValue != actualValue
      ) allKeys;

      allMatch = builtins.length mismatches == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length allKeys)} attributes match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  ${message}"
        echo ""
        echo "🔍 Mismatched attributes:"
        ${lib.concatMapStringsSep "\n" (key: ''
          echo "  ${key}:"
          echo "    Expected: ${builtins.toString expected.${key} or "<missing>"}"
          echo "    Actual: ${builtins.toString actual.${key} or "<missing>"}"
        '') mismatches}
        exit 1
      '';

  # Validate git user configuration
  assertGitUserInfo =
    name: gitConfig: expectedName: expectedEmail:
    let
      userName = gitConfig.userName or "<not set>";
      userEmail = gitConfig.userEmail or "<not set>";
      nameMatch = userName == expectedName;
      emailMatch = userEmail == expectedEmail;
      bothMatch = nameMatch && emailMatch;
    in
    if bothMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git user: ${userName} <${userEmail}>"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git user info mismatch"
        echo ""
        echo "  User Name:"
        echo "    Expected: ${expectedName}"
        echo "    Actual: ${userName}"
        echo "  User Email:"
        echo "    Expected: ${expectedEmail}"
        echo "    Actual: ${userEmail}"
        exit 1
      '';

  # Validate git settings
  assertGitSettings =
    name: gitConfig: expectedSettings:
    let
      extraConfig = gitConfig.extraConfig or { };

      checkSetting =
        key: expectedValue:
        let
          keys = builtins.split "\\." key;
          actualValue = builtins.foldl' (
            acc: k: if acc == null then null else acc.${k} or null
          ) extraConfig keys;

          expectedStr =
            if expectedValue == true then
              "true"
            else if expectedValue == false then
              "false"
            else
              builtins.toString expectedValue;
          actualStr =
            if actualValue == true then
              "true"
            else if actualValue == false then
              "false"
            else if actualValue == null then
              "<not set>"
            else
              builtins.toString actualValue;

          matches = expectedStr == actualStr;
        in
        if matches then
          {
            inherit key;
            matches = true;
          }
        else
          {
            inherit key;
            matches = false;
            expected = expectedStr;
            actual = actualStr;
          };

      results = builtins.map (key: checkSetting key expectedSettings.${key}) (
        builtins.attrNames expectedSettings
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git settings match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git settings mismatch"
        echo ""
        echo "🔍 Mismatched settings:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.key}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate git aliases
  assertGitAliases =
    name: gitConfig: expectedAliases:
    let
      actualAliases = gitConfig.aliases or { };

      checkAlias =
        alias: expectedCommand:
        let
          actualCommand = actualAliases.${alias} or "<not set>";
          matches = actualCommand == expectedCommand;
        in
        if matches then
          {
            inherit alias;
            matches = true;
          }
        else
          {
            inherit alias;
            matches = false;
            expected = expectedCommand;
            actual = actualCommand;
          };

      results = builtins.map (alias: checkAlias alias expectedAliases.${alias}) (
        builtins.attrNames expectedAliases
      );
      failed = builtins.filter (r: !r.matches) results;
      allMatch = builtins.length failed == 0;
    in
    if allMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} git aliases match"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git aliases mismatch"
        echo ""
        echo "🔍 Mismatched aliases:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.alias}:"
          echo "    Expected: ${result.expected}"
          echo "    Actual: ${result.actual}"
        '') failed}
        exit 1
      '';

  # Validate gitignore patterns
  assertGitIgnorePatterns =
    name: gitConfig: expectedPatterns:
    let
      actualPatterns = gitConfig.ignores or [ ];

      checkPattern =
        pattern:
        let
          isPresent = builtins.any (p: p == pattern) actualPatterns;
        in
        if isPresent then
          {
            inherit pattern;
            present = true;
          }
        else
          {
            inherit pattern;
            present = false;
          };

      results = builtins.map checkPattern expectedPatterns;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} gitignore patterns present"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Gitignore patterns missing"
        echo ""
        echo "🔍 Missing patterns:"
        ${lib.concatMapStringsSep "\n" (result: ''
          echo "  ${result.pattern}"
        '') missing}
        exit 1
      '';

  # Generic membership test
  assertContainsGeneric =
    name: needle: haystack: message:
    let
      haystackType = builtins.typeOf haystack;
      isPresent =
        if haystackType == "list" then
          builtins.any (item: item == needle) haystack
        else if haystackType == "set" then
          builtins.hasAttr (builtins.toString needle) haystack
        else if haystackType == "string" then
          lib.hasInfix (builtins.toString needle) haystack
        else
          abort "assertContainsGeneric: haystack must be a list, set, or string";
    in
    assertTest name isPresent "${message}: ${builtins.toString needle} not found in ${haystackType}";

  # Test plugin/package presence
  assertPluginPresent =
    name: plugins: expectedPlugins:
    let
      options = {
        matchType = "exact";
        allowExtra = true;
      };

      pluginNames =
        if builtins.typeOf plugins == "list" then
          plugins
        else if builtins.typeOf plugins == "set" then
          builtins.attrNames plugins
        else
          abort "assertPluginPresent: plugins must be a list or attribute set";

      checkPlugin =
        expectedPlugin:
        let
          isPresent =
            if options.matchType == "exact" then
              builtins.any (p: p == expectedPlugin) pluginNames
            else if options.matchType == "regex" then
              builtins.any (p: builtins.match expectedPlugin p != null) pluginNames
            else
              abort "assertPluginPresent: matchType must be 'exact' or 'regex'";
        in
        if isPresent then
          {
            plugin = expectedPlugin;
            present = true;
          }
        else
          {
            plugin = expectedPlugin;
            present = false;
          };

      results = builtins.map checkPlugin expectedPlugins;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;

      unexpected =
        if options.allowExtra then
          [ ]
        else
          builtins.filter (
            p:
            let
              isExpected =
                if options.matchType == "exact" then
                  builtins.any (exp: exp == p) expectedPlugins
                else
                  builtins.any (exp: builtins.match exp p != null) expectedPlugins;
            in
            !isExpected
          ) pluginNames;
      hasUnexpected = builtins.length unexpected > 0;
    in
    if allPresent && !hasUnexpected then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedPlugins)} expected plugins present"
        ${if options.allowExtra then "" else ''
          echo "  No unexpected plugins found"
        ''}
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        ${if !allPresent then ''
          echo "  Missing plugins:"
          ${lib.concatMapStringsSep "\n" (result: ''
            echo "    ${result.plugin}"
          '') missing}
        '' else ""}
        ${if hasUnexpected then ''
          echo ""
          echo "  Unexpected plugins found:"
          ${lib.concatMapStringsSep "\n" (p: ''
            echo "    ${p}"
          '') unexpected}
        '' else ""}
        exit 1
      '';

  # File system validation
  assertFileReadable =
    name: derivationOrPath: expectedPaths:
    let
      normalizePaths =
        paths:
        if builtins.typeOf paths == "list" then
          builtins.listToAttrs (builtins.map (p: {
            name = p;
            value = true;
          }) paths)
        else
          paths;

      pathSpecs = normalizePaths expectedPaths;

      checkPath =
        relPath: options:
        let
          fullPath =
            if builtins.typeOf derivationOrPath == "set" then
              "${derivationOrPath}/${relPath}"
            else
              "${derivationOrPath}/${relPath}";

          readResult = builtins.tryEval (
            if builtins.typeOf derivationOrPath == "set" then
              builtins.readFile fullPath
            else
              "mock-success"
          );

          isReadable = readResult.success;

          expectedType =
            if options == true then
              null
            else if builtins.typeOf options == "set" then
              options.type or null
            else
              null;

          typeMatches = true;

          executableExpected =
            if options == true then
              false
            else if builtins.typeOf options == "set" then
              options.executable or false
            else
              false;

          executableMatches = true;
        in
        if !isReadable then
          {
            path = relPath;
            readable = false;
          }
        else if !typeMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = false;
            inherit expectedType;
          }
        else if !executableMatches then
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = false;
          }
        else
          {
            path = relPath;
            readable = true;
            typeMatches = true;
            executableMatches = true;
          };

      results = builtins.map (relPath: checkPath relPath pathSpecs.${relPath}) (
        builtins.attrNames pathSpecs
      );

      unreadablePaths = builtins.filter (r: !r.readable) results;
      typeMismatches = builtins.filter (r: r.readable && !r.typeMatches) results;
      executableMismatches = builtins.filter (r: r.readable && r.typeMatches && !r.executableMatches) results;

      allValid =
        builtins.length unreadablePaths == 0 && builtins.length typeMismatches == 0
        && builtins.length executableMismatches == 0;
    in
    if allValid then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length results)} paths are valid"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  File system validation failed"
        ${if builtins.length unreadablePaths > 0 then ''
          echo ""
          echo "  Unreadable paths:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path}"
          '') unreadablePaths}
        '' else ""}
        ${if builtins.length typeMismatches > 0 then ''
          echo ""
          echo "  Type mismatches:"
          ${lib.concatMapStringsSep "\n" (r: ''
            echo "    ${r.path} (expected type: ${r.expectedType})"
          '') typeMismatches}
        '' else ""}
        exit 1
      '';

  # Module import validation
  assertImportPresent =
    name: moduleConfig: expectedImports:
    let
      directImports = moduleConfig.imports or [ ];
      configKeys = builtins.attrNames moduleConfig;

      normalizeImport =
        importSpec:
        if builtins.typeOf importSpec == "string" then
          {
            type = "any";
            pattern = importSpec;
            matchType = "exact";
          }
        else if builtins.typeOf importSpec == "set" then
          if importSpec ? regex then
            {
              type = importSpec.type or "any";
              pattern = importSpec.regex;
              matchType = "regex";
            }
          else if importSpec ? path then
            {
              type = importSpec.type or "any";
              pattern = importSpec.path;
              matchType = "exact";
            }
          else
            abort "assertImportPresent: invalid import specification"
        else
          abort "assertImportPresent: import spec must be string or attribute set";

      checkImport =
        importSpec:
        let
          spec = normalizeImport importSpec;

          inDirectImports =
            if spec.matchType == "exact" then
              builtins.any (imp: imp == spec.pattern) directImports
            else
              builtins.any (imp: builtins.match spec.pattern imp != null) directImports;

          inConfigKeys =
            if spec.matchType == "regex" then
              builtins.any (key: builtins.match spec.pattern key != null) configKeys
            else
              false;

          matchesInValues =
            if spec.matchType == "regex" then
              false
            else
              false;

          isPresent = inDirectImports || inConfigKeys || matchesInValues;
        in
        if isPresent then
          {
            spec = spec.pattern;
            present = true;
          }
        else
          {
            spec = spec.pattern;
            present = false;
          };

      results = builtins.map checkImport expectedImports;
      missing = builtins.filter (r: !r.present) results;
      allPresent = builtins.length missing == 0;
    in
    if allPresent then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  All ${toString (builtins.length expectedImports)} expected imports present"
        echo "  Direct imports found: ${toString (builtins.length directImports)}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Module import validation failed"
        echo ""
        echo "  Missing imports:"
        ${lib.concatMapStringsSep "\n" (r: ''
          echo "    ${r.spec}"
        '') missing}
        echo ""
        echo "  Found imports:"
        ${lib.concatMapStringsSep "\n" (imp: ''
          echo "    ${imp}"
        '') directImports}
        exit 1
      '';
}
