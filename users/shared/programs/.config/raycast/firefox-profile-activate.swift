import AppKit
import Darwin

func fail(_ message: String) -> Never {
  fputs("\(message)\n", stderr)
  exit(1)
}

guard CommandLine.arguments.count == 2,
      let pid = Int32(CommandLine.arguments[1]),
      let application = NSRunningApplication(processIdentifier: pid) else {
  fail("usage: firefox-profile-activate <pid>")
}

guard application.activate(options: [.activateIgnoringOtherApps, .activateAllWindows]) else {
  fail("could not activate Firefox process: \(pid)")
}
