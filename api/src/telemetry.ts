import { config } from "dotenv";
config({ path: "../.env", quiet: true });

// Disable the default logs exporter — NodeSDK auto-creates one pointing at
// localhost:4318 which produces constant ECONNREFUSED spam in a demo context.
// Traces and metrics are configured explicitly below.
process.env.OTEL_LOGS_EXPORTER = "none";

import { diag, DiagConsoleLogger, DiagLogLevel } from "@opentelemetry/api";
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.INFO);

import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
// Dynatrace's OTLP endpoint only accepts protobuf (application/x-protobuf),
// not JSON. The *-http variants of these exporters default to JSON.
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-proto";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-proto";
import { PeriodicExportingMetricReader } from "@opentelemetry/sdk-metrics";
import { resourceFromAttributes } from "@opentelemetry/resources";
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} from "@opentelemetry/semantic-conventions";

// Parse OTEL_EXPORTER_OTLP_HEADERS from .env and attach Content-Type
// explicitly. Dynatrace rejects with HTTP 415 if Content-Type is missing
// or mangled, and the SDK's auto-merging of env-var headers was dropping it.
const otlpHeaders: Record<string, string> = {
  "Content-Type": "application/x-protobuf",
};
const rawHeaders = process.env.OTEL_EXPORTER_OTLP_HEADERS ?? "";
for (const pair of rawHeaders.split(",")) {
  const eq = pair.indexOf("=");
  if (eq > 0) {
    const k = pair.slice(0, eq).trim();
    const v = pair.slice(eq + 1).trim();
    if (k) otlpHeaders[k] = v;
  }
}

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? "")
  .trim()
  .replace(/\/+$/, "");

// Prevent the SDK's internal env-var parsing from overriding our explicit
// exporter config (which is what produced the 415 in the first place).
delete process.env.OTEL_EXPORTER_OTLP_HEADERS;
delete process.env.OTEL_EXPORTER_OTLP_ENDPOINT;

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    [ATTR_SERVICE_NAME]: "orders-api",
    [ATTR_SERVICE_VERSION]: "0.1.0",
  }),
  traceExporter: new OTLPTraceExporter({
    url: `${endpoint}/v1/traces`,
    headers: otlpHeaders,
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: `${endpoint}/v1/metrics`,
      headers: otlpHeaders,
    }),
    exportIntervalMillis: 15000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Disable fs instrumentation — way too noisy for a demo.
      "@opentelemetry/instrumentation-fs": { enabled: false },
    }),
  ],
});

sdk.start();

process.on("SIGTERM", () => {
  sdk.shutdown().finally(() => process.exit(0));
});
process.on("SIGINT", () => {
  sdk.shutdown().finally(() => process.exit(0));
});
