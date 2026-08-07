export default async function k8sMonitor({ $ }) {
  let warningEvents = [];
  let intervalId = null;

  const poll = async () => {
    try {
      const ns = process.env.NAMESPACE;
      const result = ns
        ? await $`kubectl get events -n ${ns} --field-selector type=Warning -o json 2>/dev/null`
        : await $`kubectl get events --field-selector type=Warning -o json 2>/dev/null`;
      const data = JSON.parse(result.stdout);
      warningEvents = (data.items || []).slice(-30).map((item) => ({
        type: item.type,
        reason: item.reason || "",
        message: item.message || "",
        object: [item.involvedObject?.kind, item.involvedObject?.name]
          .filter(Boolean)
          .join("/"),
        count: item.count || 1,
        lastTimestamp: item.lastTimestamp || "",
      }));
    } catch {
      // kubectl unavailable or no cluster access — skip silently
    }
  };

  await poll();
  intervalId = setInterval(poll, 10_000);

  const getQuotaIssues = () =>
    warningEvents.filter(
      (e) =>
        e.reason === "FailedCreate" ||
        e.reason === "FailedScheduling" ||
        e.message?.toLowerCase().includes("quota"),
    );

  const getCritical = () =>
    warningEvents.filter(
      (e) =>
        e.reason === "FailedCreate" ||
        e.reason === "FailedScheduling" ||
        e.reason === "BackOff" ||
        e.reason === "Error" ||
        e.message?.toLowerCase().includes("quota") ||
        e.message?.toLowerCase().includes("resource"),
    );

  return {
    tool: {
      k8s_warnings: {
        description:
          "Show recent Kubernetes warning events in the current namespace. Use to check resource quotas, pod failures, and other cluster issues.",
        parameters: {
          type: "object",
          properties: {
            limit: {
              type: "number",
              description: "Number of events to show (default: 10)",
            },
            quota: {
              type: "boolean",
              description: "Only show quota-related events (FailedCreate, exceeded quota)",
            },
          },
        },
        execute: async (args) => {
          const limit = args.limit ?? 10;
          const quotaFilter = args.quota ?? false;
          let events = quotaFilter ? getQuotaIssues() : warningEvents;
          if (events.length === 0) return "No recent warning events found.";
          const label = quotaFilter ? "Quota-related warnings" : "Warning events";
          const count = Math.min(limit, events.length);
          return (
            `## Kubernetes ${label} (last ${count})\n` +
            events
              .slice(0, limit)
              .map((e) => `[${e.reason}] ${e.object}: ${e.message}`)
              .join("\n")
          );
        },
      },
    },

    "experimental.chat.system.transform": async (_input, output) => {
      const critical = getCritical();
      if (critical.length === 0) return;
      output.system.push(
        `## Active Kubernetes Issues\n` +
          `Active Kubernetes warnings${process.env.NAMESPACE ? ` in namespace "${process.env.NAMESPACE}"` : ""}:\n` +
          critical
            .slice(0, 5)
            .map((e) => `- ${e.reason} on ${e.object}: ${e.message}`)
            .join("\n") +
          `\nIf you are about to deploy, these issues may affect your deployment. ` +
          `Run the \`k8s_warnings\` tool to see all recent events.`,
      );
    },

    "tool.execute.after": async (input, output) => {
      if (!output?.metadata?.exitCode || output.metadata.exitCode === 0) {
        return;
      }
      const k8sTools = ["bash", "exec_shell", "run_terminal"];
      if (!k8sTools.includes(input.tool)) return;
      const quotaIssues = getQuotaIssues();
      if (quotaIssues.length === 0) return;
      output.output +=
        `\n\n⚠️ **Kubernetes Resource Issues Detected**\n` +
        quotaIssues
          .slice(0, 3)
          .map((e) => `- ${e.reason}: ${e.message}`)
          .join("\n") +
        `\n\nRun \`k8s_warnings\` to see full details.`;
    },

    dispose: async () => {
      if (intervalId) {
        clearInterval(intervalId);
        intervalId = null;
      }
    },
  };
}
