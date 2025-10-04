# Unit Test Examples for Comprehensive Testing Framework
# Demonstrates best practices for writing unit tests using nix-unit

{ lib, ... }:

let
  # Example utility functions to test
  stringUtils = {
    capitalize =
      str:
      if str == null || str == "" then
        str
      else
        (lib.toUpper (lib.substring 0 1 str)) + (lib.substring 1 (-1) str);

    slugify = str: lib.toLower (lib.replaceStrings [ " " "_" ] [ "-" "-" ] str);

    truncate =
      maxLen: str: if lib.stringLength str <= maxLen then str else (lib.substring 0 maxLen str) + "...";
  };

  listUtils = {
    unique = list: lib.unique (lib.sort lib.lessThan list);

    partition = predicate: list: lib.partition predicate list;

    chunk =
      size: list:
      if list == [ ] || size <= 0 then
        [ ]
      else
        let
          head = lib.take size list;
          tail = lib.drop size list;
        in
        [ head ] ++ (listUtils.chunk size tail);
  };

  configUtils = {
    mergeConfigs = configs: lib.foldl' lib.recursiveUpdate { } configs;

    validateConfig = config: config ? name && config ? enable && lib.isString config.name;

    normalizeConfig =
      config:
      config
      // {
        enable = config.enable or false;
        priority = config.priority or 100;
      };
  };

in
{
  # String utility tests
  testStringUtilsCapitalizationBasic = {
    expr = stringUtils.capitalize "hello";
    expected = "Hello";
  };

  testStringUtilsCapitalizationEmpty = {
    expr = stringUtils.capitalize "";
    expected = "";
  };

  testStringUtilsCapitalizationNull = {
    expr = stringUtils.capitalize null;
    expected = null;
  };

  testStringUtilsCapitalizationSingle = {
    expr = stringUtils.capitalize "a";
    expected = "A";
  };

  testStringUtilsSlugifyBasic = {
    expr = stringUtils.slugify "Hello World";
    expected = "hello-world";
  };

  testStringUtilsSlugifyUnderscore = {
    expr = stringUtils.slugify "hello_world_test";
    expected = "hello-world-test";
  };

  testStringUtilsSlugifyMixed = {
    expr = stringUtils.slugify "Hello World_Test Case";
    expected = "hello-world-test-case";
  };

  testStringUtilsTruncateShort = {
    expr = stringUtils.truncate 10 "hello";
    expected = "hello";
  };

  testStringUtilsTruncateLong = {
    expr = stringUtils.truncate 5 "hello world";
    expected = "hello...";
  };

  testStringUtilsTruncateExact = {
    expr = stringUtils.truncate 5 "hello";
    expected = "hello";
  };

  # List utility tests
  testListUtilsUniqueBasic = {
    expr = listUtils.unique [
      3
      1
      2
      1
      3
      2
    ];
    expected = [
      1
      2
      3
    ];
  };

  testListUtilsUniqueEmpty = {
    expr = listUtils.unique [ ];
    expected = [ ];
  };

  testListUtilsUniqueSingle = {
    expr = listUtils.unique [ 42 ];
    expected = [ 42 ];
  };

  testListUtilsPartitionBasic = {
    expr = listUtils.partition (x: x > 5) [
      1
      6
      3
      8
      2
      9
    ];
    expected = {
      right = [
        6
        8
        9
      ];
      wrong = [
        1
        3
        2
      ];
    };
  };

  testListUtilsPartitionEmpty = {
    expr = listUtils.partition (x: x > 5) [ ];
    expected = {
      right = [ ];
      wrong = [ ];
    };
  };

  testListUtilsPartitionAllTrue = {
    expr = listUtils.partition (x: true) [
      1
      2
      3
    ];
    expected = {
      right = [
        1
        2
        3
      ];
      wrong = [ ];
    };
  };

  testListUtilsChunkBasic = {
    expr = listUtils.chunk 2 [
      1
      2
      3
      4
      5
    ];
    expected = [
      [
        1
        2
      ]
      [
        3
        4
      ]
      [ 5 ]
    ];
  };

  testListUtilsChunkEmpty = {
    expr = listUtils.chunk 2 [ ];
    expected = [ ];
  };

  testListUtilsChunkInvalidSize = {
    expr = listUtils.chunk 0 [
      1
      2
      3
    ];
    expected = [ ];
  };

  # Configuration utility tests
  testConfigUtilsMergeBasic = {
    expr = configUtils.mergeConfigs [
      {
        a = 1;
        b = {
          c = 2;
        };
      }
      {
        b = {
          d = 3;
        };
        e = 4;
      }
    ];
    expected = {
      a = 1;
      b = {
        c = 2;
        d = 3;
      };
      e = 4;
    };
  };

  testConfigUtilsMergeEmpty = {
    expr = configUtils.mergeConfigs [ ];
    expected = { };
  };

  testConfigUtilsMergeOverride = {
    expr = configUtils.mergeConfigs [
      { a = 1; }
      { a = 2; }
    ];
    expected = {
      a = 2;
    };
  };

  testConfigUtilsValidateValid = {
    expr = configUtils.validateConfig {
      name = "test-service";
      enable = true;
      extra = "data";
    };
    expected = true;
  };

  testConfigUtilsValidateInvalidNoName = {
    expr = configUtils.validateConfig {
      enable = true;
    };
    expected = false;
  };

  testConfigUtilsValidateInvalidBadName = {
    expr = configUtils.validateConfig {
      name = 123;
      enable = true;
    };
    expected = false;
  };

  testConfigUtilsNormalizeBasic = {
    expr = configUtils.normalizeConfig {
      name = "test";
      enable = true;
      priority = 50;
    };
    expected = {
      name = "test";
      enable = true;
      priority = 50;
    };
  };

  testConfigUtilsNormalizeDefaults = {
    expr = configUtils.normalizeConfig {
      name = "test";
    };
    expected = {
      name = "test";
      enable = false;
      priority = 100;
    };
  };

  # Error handling tests
  testErrorHandlingNullInput = {
    expr = builtins.tryEval (stringUtils.capitalize null);
    expected = {
      success = true;
      value = null;
    };
  };

  testErrorHandlingEmptyList = {
    expr = builtins.tryEval (listUtils.unique [ ]);
    expected = {
      success = true;
      value = [ ];
    };
  };

  # Edge case tests
  testEdgeCaseVeryLongString = {
    expr = stringUtils.truncate 3 (lib.concatStrings (lib.genList (_: "x") 1000));
    expected = "xxx...";
  };

  testEdgeCaseLargeList = {
    expr = builtins.length (listUtils.unique (lib.range 1 1000));
    expected = 1000;
  };

  # Property-based testing examples
  testPropertyStringCapitalizationIdempotent = {
    expr =
      let
        testString = "hello";
        capitalized = stringUtils.capitalize testString;
        doubleCapitalized = stringUtils.capitalize capitalized;
      in
      capitalized == doubleCapitalized;
    expected = true;
  };

  testPropertyListUniqueIdempotent = {
    expr =
      let
        testList = [
          1
          2
          2
          3
          3
          3
        ];
        unique1 = listUtils.unique testList;
        unique2 = listUtils.unique unique1;
      in
      unique1 == unique2;
    expected = true;
  };

  testPropertyConfigNormalizationConsistent = {
    expr =
      let
        config = {
          name = "test";
          priority = 42;
        };
        normalized1 = configUtils.normalizeConfig config;
        normalized2 = configUtils.normalizeConfig normalized1;
      in
      normalized1 == normalized2;
    expected = true;
  };

  # Performance characteristics tests
  testPerformanceStringOperations = {
    expr =
      let
        longString = lib.concatStrings (lib.genList (i: "word${toString i} ") 100);
        result = stringUtils.slugify longString;
      in
      lib.hasPrefix "word0-" result;
    expected = true;
  };

  testPerformanceListOperations = {
    expr =
      let
        largeList = lib.range 1 1000;
        result = listUtils.chunk 10 largeList;
      in
      builtins.length result == 100;
    expected = true;
  };
}
