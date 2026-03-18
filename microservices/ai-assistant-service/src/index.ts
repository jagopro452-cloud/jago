import express from "express";

const app = express();
const port = Number(process.env.AI_ASSISTANT_PORT || 7104);

app.use(express.json());

type VoiceIntent = "book_ride" | "send_parcel" | "track_trip" | "cancel_trip" | "unknown";

function normalizeTranscript(input: string): string {
  return String(input || "")
    .trim()
    .replace(/\s+/g, " ")
    .replace(/[!?]/g, "")
    .toLowerCase();
}

function detectService(text: string): "bike" | "auto" | "car" | "parcel" {
  if (/parcel|package|courier|delivery|dabba/.test(text)) return "parcel";
  if (/bike|scooty|two\s?wheeler/.test(text)) return "bike";
  if (/auto|rickshaw|auto\s?ride/.test(text)) return "auto";
  return "car";
}

function parseFromTo(text: string) {
  const english = text.match(/from\s+(.+?)\s+to\s+(.+?)(?:\.|,|$)/i);
  if (english) {
    return {
      pickup: english[1].trim(),
      destination: english[2].trim(),
      language: "en",
    };
  }

  // Telugu-style phrasing: "X nundi Y ki bike kavali"
  const telugu = text.match(/(.+?)\s+nundi\s+(.+?)\s+ki(?:\s+.+)?$/i);
  if (telugu) {
    return {
      pickup: telugu[1].trim(),
      destination: telugu[2].trim(),
      language: "te-en",
    };
  }

  return { pickup: null, destination: null, language: "unknown" };
}

function detectIntent(text: string): VoiceIntent {
  if (/cancel|abort|stop ride/.test(text)) return "cancel_trip";
  if (/track|where is|eta|status/.test(text)) return "track_trip";
  if (/parcel|package|courier|delivery/.test(text)) return "send_parcel";
  if (/ride|book|cab|auto|bike|car|nundi|to\s+/.test(text)) return "book_ride";
  return "unknown";
}

app.get("/health", (_req, res) => {
  res.json({ service: "ai-assistant-service", status: "ok", timestamp: new Date().toISOString() });
});

app.post("/internal/voice/intent", (req, res) => {
  const { transcript = "" } = req.body || {};
  const text = normalizeTranscript(transcript);
  const wakeWordDetected = /^(hey\s+jago\s*pro|hi\s+jago\s*pro|jago\s*pro)/.test(text);
  const intent = detectIntent(text);
  const serviceSuggestion = detectService(text);
  const route = parseFromTo(text);

  const confidenceBase = intent === "unknown" ? 0.3 : 0.78;
  const confidence = Math.min(0.98, confidenceBase + (route.destination ? 0.12 : 0) + (wakeWordDetected ? 0.04 : 0));

  res.json({
    wakeWord: "hey jago pro",
    wakeWordDetected,
    transcript,
    intent,
    confidence: Number(confidence.toFixed(2)),
    entities: {
      language: route.language,
      serviceSuggestion,
      pickup: route.pickup || "gps_auto",
      destination: route.destination,
    },
    actionPlan: [
      "detect_pickup",
      route.destination ? "resolve_destination" : "ask_destination",
      "estimate_fare",
      "create_booking_request",
    ],
  });
});

app.post("/internal/voice/action/execute", (req, res) => {
  const { intent, entities } = req.body || {};
  const nextAction = intent === "book_ride" || intent === "send_parcel" ? "booking_quote" : "assistant_reply";
  res.json({
    accepted: true,
    intent,
    entities,
    nextAction,
    automation: {
      shouldCreateDraftBooking: intent === "book_ride" || intent === "send_parcel",
      requiredFields: ["pickup", "destination", "serviceSuggestion"],
    },
  });
});

app.listen(port, () => {
  console.log(`[ai-assistant-service] listening on ${port}`);
});
