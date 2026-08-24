import { Action, ActionPanel, Icon, List, showToast, Toast } from "@raycast/api";
import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { promisify } from "node:util";
import { useEffect, useState } from "react";

const execFileAsync = promisify(execFile);
const firefoxDataDir =
  process.env.FF_FIREFOX_DATA_DIR ?? path.join(os.homedir(), "Library/Application Support/Firefox");
const sqliteBinary = process.env.FF_SQLITE3_BINARY ?? "/usr/bin/sqlite3";
const profilesIni = path.join(firefoxDataDir, "profiles.ini");

type FirefoxProfile = {
  name: string;
  path: string;
};

type ProfileSection = {
  name?: string;
  path?: string;
  isRelative?: string;
  storeId?: string;
};

function resolveProfilePath(profilePath: string) {
  return path.isAbsolute(profilePath) ? profilePath : path.join(firefoxDataDir, profilePath);
}

async function readProfilesIni() {
  const content = await fs.readFile(profilesIni, "utf8");
  const sections = new Map<string, ProfileSection>();
  let section = "";

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    const sectionMatch = line.match(/^\[([^\]]+)\]$/);
    if (sectionMatch) {
      section = sectionMatch[1];
      sections.set(section, {});
      continue;
    }

    if (!section || !line.includes("=")) continue;
    const separator = line.indexOf("=");
    const key = line.slice(0, separator);
    const value = line.slice(separator + 1);
    const current = sections.get(section) ?? {};
    if (key === "Name") current.name = value;
    if (key === "Path") current.path = value;
    if (key === "IsRelative") current.isRelative = value;
    if (key === "StoreID") current.storeId = value;
    sections.set(section, current);
  }

  return sections;
}

async function existingProfile(name: string, profilePath: string): Promise<FirefoxProfile | null> {
  const resolvedPath = resolveProfilePath(profilePath);
  try {
    const stats = await fs.stat(resolvedPath);
    return stats.isDirectory() ? { name, path: resolvedPath } : null;
  } catch {
    return null;
  }
}

async function readGroupedProfiles(storeId: string): Promise<FirefoxProfile[]> {
  const database = path.join(firefoxDataDir, "Profile Groups", `${storeId}.sqlite`);
  const query = "SELECT name, path FROM Profiles ORDER BY name COLLATE NOCASE, id;";
  const { stdout } = await execFileAsync(
    sqliteBinary,
    ["-readonly", "-noheader", "-separator", "\t", database, query],
    { maxBuffer: 1024 * 1024 },
  );
  const profiles: FirefoxProfile[] = [];

  for (const row of stdout.split("\n")) {
    if (!row) continue;
    const separator = row.indexOf("\t");
    if (separator < 1) continue;
    const profile = await existingProfile(row.slice(0, separator), row.slice(separator + 1));
    if (profile) profiles.push(profile);
  }

  return profiles;
}

async function readProfiles(): Promise<FirefoxProfile[]> {
  const sections = await readProfilesIni();
  const storeId = [...sections.entries()].find(
    ([section, values]) => section.startsWith("Profile") && values.storeId,
  )?.[1].storeId;

  if (storeId) {
    try {
      const groupedProfiles = await readGroupedProfiles(storeId);
      if (groupedProfiles.length > 0) return groupedProfiles;
    } catch {
      // Fall back to profiles.ini when the Profile Groups database is unavailable.
    }
  }

  const legacyProfiles: FirefoxProfile[] = [];
  for (const [section, values] of sections) {
    if (!section.startsWith("Profile") || !values.name || !values.path) continue;
    const profile = await existingProfile(values.name, values.path);
    if (profile) legacyProfiles.push(profile);
  }
  return legacyProfiles;
}

function profileScriptPath() {
  return path.join(os.homedir(), ".config/raycast/script-commands/firefox-profile.sh");
}

async function runProfileScript(args: string[] = []) {
  return execFileAsync(profileScriptPath(), args, { maxBuffer: 1024 * 1024 });
}

async function openProfile(name: string) {
  await runProfileScript([name]);
  await showToast({ style: Toast.Style.Success, title: `Opened Firefox profile: ${name}` });
}

async function openProfileManager() {
  await runProfileScript();
  await showToast({ style: Toast.Style.Success, title: "Opened Firefox Profile Manager" });
}

export default function ChooseProfile() {
  const [profiles, setProfiles] = useState<FirefoxProfile[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string>();

  useEffect(() => {
    readProfiles()
      .then(setProfiles)
      .catch((reason: Error) => setError(reason.message))
      .finally(() => setIsLoading(false));
  }, []);

  return (
    <List isLoading={isLoading} navigationTitle="Choose Firefox Profile" searchBarPlaceholder="Search profiles">
      <List.Item
        key="profile-manager"
        title="Profile Manager"
        subtitle="Choose or create a Firefox profile"
        icon={Icon.Gear}
        actions={
          <ActionPanel>
            <Action title="Open Profile Manager" icon={Icon.ArrowRight} onAction={openProfileManager} />
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
              <Action title="Open Profile" icon={Icon.ArrowRight} onAction={() => openProfile(profile.name)} />
            </ActionPanel>
          }
        />
      ))}
      {error ? <List.EmptyView title="Could not read Firefox profiles" description={error} /> : null}
    </List>
  );
}
