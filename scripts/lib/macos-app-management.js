// Read-only private SPI: keep macOS-specific compatibility in this file.
// 0 = allowed, 1 = denied, other results or unavailable API = unknown.
function run() {
  try {
    ObjC.import("Foundation");
    ObjC.bindFunction("dlopen", ["void *", ["char *", "int"]]);
    $.dlopen(
      "/System/Library/PrivateFrameworks/TCC.framework/Versions/A/TCC",
      1,
    );
    ObjC.bindFunction("TCCAccessPreflight", ["int", ["id", "id"]]);
    const status = $.TCCAccessPreflight(
      $("kTCCServiceSystemPolicyAppBundles"),
      null,
    );
    return status === 0 ? "granted" : status === 1 ? "denied" : "unknown";
  } catch (error) {
    return "unknown";
  }
}
