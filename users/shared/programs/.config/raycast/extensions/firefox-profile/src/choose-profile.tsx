import { Action, ActionPanel, Icon, List, showToast, Toast } from "@raycast/api";
import { usePromise } from "@raycast/utils";
import { execFile } from "node:child_process";
import * as os from "node:os";
import * as path from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const profileLauncher =
  process.env.FF_FIREFOX_LAUNCHER ?? path.join(os.homedir(), ".config/raycast/firefox-profile-launcher.zsh");

type FirefoxProfile = {
  name: string;
  path: string;
};

async function readProfiles(): Promise<FirefoxProfile[]> {
  const { stdout } = await execFileAsync(profileLauncher, ["--list-paths"], {
    maxBuffer: 1024 * 1024,
  });

  return stdout.split("\n").flatMap((row) => {
    if (!row) return [];
    const separator = row.indexOf("\t");
    if (separator < 1) return [];

    const name = row.slice(0, separator);
    const profilePath = row.slice(separator + 1);
    return name && profilePath ? [{ name, path: profilePath }] : [];
  });
}

function profileScriptPath() {
  return path.join(os.homedir(), ".config/raycast/script-commands/firefox-profile.sh");
}

async function runProfileScript(args: string[] = []) {
  return execFileAsync(profileScriptPath(), args, { maxBuffer: 1024 * 1024 });
}

function errorMessage(reason: unknown) {
  return reason instanceof Error ? reason.message : String(reason);
}

async function openDefaultProfile() {
  try {
    await execFileAsync("/usr/bin/open", ["-a", "Firefox"]);
    await showToast({ style: Toast.Style.Success, title: "Opened Default Firefox" });
  } catch (reason) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Could not open Default Firefox",
      message: errorMessage(reason),
    });
  }
}

async function openProfile(profile: FirefoxProfile) {
  try {
    await runProfileScript([profile.path]);
    await showToast({ style: Toast.Style.Success, title: `Opened Firefox profile: ${profile.name}` });
  } catch (reason: unknown) {
    await showToast({
      style: Toast.Style.Failure,
      title: `Could not open Firefox profile: ${profile.name}`,
      message: errorMessage(reason),
    });
  }
}

export default function ChooseProfile() {
  const {
    data: profiles = [],
    isLoading,
    error,
    revalidate,
  } = usePromise(readProfiles, [], {
    failureToastOptions: { title: "Could not read Firefox profiles" },
  });

  return (
    <List isLoading={isLoading} navigationTitle="Choose Firefox Profile" searchBarPlaceholder="Search profiles">
      <List.Item
        key="default-profile"
        title="Open Default Firefox"
        subtitle="Open Firefox with its default profile"
        icon={Icon.Globe}
        actions={
          <ActionPanel>
            <Action title="Open Default Firefox" icon={Icon.ArrowRight} onAction={openDefaultProfile} />
            <Action title="Refresh Profiles" icon={Icon.RotateClockwise} onAction={revalidate} />
          </ActionPanel>
        }
      />
      {profiles.map((profile) => (
        <List.Item
          key={profile.path}
          title={profile.name}
          subtitle={profile.path}
          icon={Icon.Person}
          actions={
            <ActionPanel>
              <Action title="Open Profile" icon={Icon.ArrowRight} onAction={() => openProfile(profile)} />
              <Action title="Refresh Profiles" icon={Icon.RotateClockwise} onAction={revalidate} />
            </ActionPanel>
          }
        />
      ))}
      {error ? (
        <List.EmptyView
          title="Could not read Firefox profiles"
          description={error.message}
          actions={
            <ActionPanel>
              <Action title="Retry" icon={Icon.RotateClockwise} onAction={revalidate} />
            </ActionPanel>
          }
        />
      ) : null}
    </List>
  );
}
