#!/usr/bin/env node
// Prints the exercise-feedback Worker's request stats from Cloudflare's
// Workers Analytics (GraphQL) API. Reuses wrangler's own local login --
// run `npx wrangler login` first if this fails with an auth error.
//
// Usage: npm run stats [-- --since=2026-09-01] [--until=2026-10-15]
// Dates default to the last 30 days, inclusive, in UTC.

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const WRANGLER_CONFIG = join(homedir(), ".wrangler", "config", "default.toml");
const WRANGLER_TOML = join(import.meta.dirname, "..", "wrangler.toml");

function readOAuthToken() {
    let toml;
    try {
        toml = readFileSync(WRANGLER_CONFIG, "utf8");
    } catch {
        throw new Error(
            `Couldn't read ${WRANGLER_CONFIG} -- run "npx wrangler login" first.`,
        );
    }
    const match = toml.match(/^oauth_token = "([^"]+)"/m);
    if (!match) {
        throw new Error(`No oauth_token found in ${WRANGLER_CONFIG} -- run "npx wrangler login".`);
    }
    return match[1];
}

function readScriptName() {
    const toml = readFileSync(WRANGLER_TOML, "utf8");
    const match = toml.match(/^name = "([^"]+)"/m);
    if (!match) throw new Error(`No "name" found in ${WRANGLER_TOML}`);
    return match[1];
}

function parseArgs(argv) {
    const args = { since: null, until: null };
    for (const arg of argv) {
        const m = arg.match(/^--(since|until)=(.+)$/);
        if (m) args[m[1]] = m[2];
    }
    const today = new Date();
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    const toISODate = (d) => d.toISOString().slice(0, 10);
    return {
        since: args.since ?? toISODate(thirtyDaysAgo),
        until: args.until ?? toISODate(today),
    };
}

async function fetchAccountId(token) {
    const resp = await fetch("https://api.cloudflare.com/client/v4/accounts", {
        headers: { Authorization: `Bearer ${token}` },
    });
    const body = await resp.json();
    if (!body.success || !body.result?.length) {
        throw new Error(`Couldn't list Cloudflare accounts: ${JSON.stringify(body.errors)}`);
    }
    return body.result[0].id;
}

async function fetchStats(token, accountId, scriptName, since, until) {
    const query = `
        query ($accountTag: string!, $since: Date!, $until: Date!, $scriptName: string!) {
            viewer {
                accounts(filter: { accountTag: $accountTag }) {
                    workersInvocationsAdaptive(
                        limit: 1000
                        filter: { date_geq: $since, date_leq: $until, scriptName: $scriptName }
                        orderBy: [date_ASC]
                    ) {
                        sum { requests errors subrequests }
                        dimensions { date }
                    }
                }
            }
        }
    `;
    const resp = await fetch("https://api.cloudflare.com/client/v4/graphql", {
        method: "POST",
        headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            query,
            variables: { accountTag: accountId, since, until, scriptName },
        }),
    });
    const body = await resp.json();
    if (body.errors) {
        throw new Error(`GraphQL error: ${JSON.stringify(body.errors)}`);
    }
    return body.data.viewer.accounts[0]?.workersInvocationsAdaptive ?? [];
}

async function main() {
    const { since, until } = parseArgs(process.argv.slice(2));
    const token = readOAuthToken();
    const scriptName = readScriptName();

    const accountId = await fetchAccountId(token);
    const rows = await fetchStats(token, accountId, scriptName, since, until);

    console.log(`${scriptName} -- requests from ${since} to ${until}\n`);

    if (rows.length === 0) {
        console.log("No requests recorded in this range.");
        return;
    }

    const pad = (s, n) => String(s).padStart(n);
    console.log(`${"date".padEnd(12)}${pad("requests", 10)}${pad("subrequests", 13)}${pad("errors", 8)}`);
    let totalRequests = 0, totalSubrequests = 0, totalErrors = 0;
    for (const row of rows) {
        const { requests, subrequests, errors } = row.sum;
        totalRequests += requests;
        totalSubrequests += subrequests;
        totalErrors += errors;
        console.log(
            `${row.dimensions.date.padEnd(12)}${pad(requests, 10)}${pad(subrequests, 13)}${pad(errors, 8)}`,
        );
    }
    console.log("-".repeat(43));
    console.log(
        `${"total".padEnd(12)}${pad(totalRequests, 10)}${pad(totalSubrequests, 13)}${pad(totalErrors, 8)}`,
    );
    console.log(
        "\n(Cloudflare's Workers Analytics is sampled, not an exact counter --\n" +
        "expect small variance between runs, especially at low volume.)",
    );
}

main().catch((err) => {
    console.error(err.message);
    process.exit(1);
});
