# Gentle Lights

Gentle Lights is a calm, gamified medication support app designed for older adults who struggle with traditional alarms and reminders.

Instead of alarms, checklists, or medical language, the app uses a simple visual metaphor — a cozy house whose lights turn on when medication is taken — to gently prompt action until it is resolved.

The app supports caregivers through a role-based interface, enabling optional verification and escalation without removing the user’s sense of autonomy or trust.

---

## Core Design Principles (Non-Negotiable)

- The problem cannot be dismissed — only resolved
- No alarms that can be silenced and forgotten
- No medical or clinical language in the user experience
- One primary action for the user
- Persistent unresolved state until medication is taken
- Progressive trust: proof and verification only when needed
- Caregiver complexity must never leak into user UI
- Calm, adult, emotionally neutral visuals

---

## The Metaphor: The House

The primary metaphor is a **small illustrated house**.

- Lights on = medication taken
- Lights dim/off = medication outstanding
- Time-of-day maps naturally to the house
- The house never “fails” or “gets sick” — it is simply waiting

### One-time clarity rule
The metaphor must be explicitly explained once during onboarding:
**“Keeping the house warm means taking your medication.”**
After that, learning is reinforced through cause-and-effect (tap → lights).

---

## User Roles

### 1. User (Nic)
- Older adult, tech-phobic
- One screen
- One primary action
- No configuration
- No schedules visible
- No medical language

### 2. Caregiver
- Family members
- Can view completion state
- Can verify or approve completion
- Can configure escalation and proof levels
- Uses the same app with role-based UI

---

## Onboarding & Account Linking (Critical)

Goal: Make onboarding simple for the user, while enabling caregivers to connect reliably across iOS/Android.

### Recommended approach: Anonymous user + caregiver pairing code
- User starts with **Anonymous Auth** (no email/password required)
- User device generates a **Pairing Code** (or QR) to link caregivers to the same family
- Caregiver enters pairing code to join that family on their device
- Once at least one caregiver is linked, the family can optionally “upgrade” auth later

#### Why anonymous auth works here
- Avoids account creation friction for a tech-phobic user
- Still allows cross-device syncing via linked family id
- Keeps initial onboarding extremely short

### Backup / Recovery Code (Non-negotiable)
Because anonymous auth can be lost if the app is deleted:
- Generate a **Recovery Code** (12–16 chars, easy to read) during onboarding
- Caregiver is encouraged to store it
- Recovery code can restore access to the same family if the user reinstalls

### Onboarding flow (User mode)
1. Welcome screen (single button: Continue)
2. Metaphor explanation screen:
   - “This little house represents you.”
   - “When you take your medication, the house stays warm and bright.”
   - “If the lights are dim, it’s just waiting for you.”
   - “When you’ve taken your medication, tap ‘Turn the lights on.’”
   - Button: “I understand”
3. Pairing screen:
   - “Let’s connect your family helper.”
   - Shows Pairing Code + QR (optional)
   - Button: “Skip for now” (but visible)
4. Recovery screen:
   - Shows Recovery Code
   - “Please keep this safe.”
   - Button: “Done”
5. Land on House screen

### Onboarding flow (Caregiver mode)
1. Choose role: “I’m helping someone”
2. Enter pairing code OR scan QR
3. Confirm join
4. Land on caregiver timeline screen

---

## UX Language & Tone (Critical)

All copy must:
- Be warm
- Be human
- Be indirect but clear
- Avoid medical terms

Examples:
- “Turn the lights on”
- “The house is still dim”
- “Needs a check-in”
- “All done”

Copy is locked early and reused consistently.

---

## Time Model

The app operates on **time windows**, not exact times:
- Morning
- Midday
- Evening
- Bedtime

Only the current window is emphasized.
Missed windows remain visually unresolved until completed or handled by caregivers.

---

## Daily State Machine

Each time window has a simple state:
- `pending` – not yet resolved
- `completedSelf` – user confirmed
- `completedVerified` – caregiver verified
- `missed` – expired without completion (optional rule)

Rules:
- A window becomes active based on local time
- If active and unresolved, the app remains visually incomplete
- Notifications continue gently until resolved
- The user can never dismiss a window — only complete it

---

## MVP (Phase 1) – Behaviour First

### Goal
Ship the smallest version that meaningfully changes behaviour.

### Features
- Onboarding flow (metaphor explanation + pairing + recovery code)
- Single house screen (placeholder visuals allowed)
- Time windows (Morning / Midday / Evening / Bedtime)
- One large button: “Turn the lights on”
- Visual state driven by completion
- Persistent unresolved state
- Gentle notifications that repeat until resolved
- Shared family link across devices (pairing code)
- Caregiver can manually mark a window as completed

### Explicitly Out of Scope
- Pill lists
- Dosages
- Streaks
- Red warning states
- Reports or charts
- Medical terminology

---

## Phase 2 – Caregiver Support

- Caregiver timeline improvements
- Manual approval workflows (confirm completion)
- Silent sync to user’s app
- Optional approval requests triggered by patterns

---

## Phase 3 – Progressive Proof

Proof added only when needed.

Proof Levels:
- Level 0: Trust-based tap
- Level 1: Passive proof (NFC / QR)
- Level 2: Caregiver confirmation required

Proof is framed as “helping the house” — never surveillance.

---

## Phase 4 – Visual Depth

- Day/night lighting changes
- Subtle animations (window glow, curtains, chimney smoke)
- Weather and seasons (optional)
- Lock screen widget showing house state

---

## Phase 5 – Intelligence & Escalation

- Pattern detection (e.g. evenings often delayed)
- Caregiver nudges based on trends
- Automatic proof escalation and reduction

---

## Phase 6 – Hardware & Accessibility (Optional)

- NFC pill box
- Physical confirmation button
- High-contrast mode
- Large text mode
- Offline-first behaviour

---

## Tech Stack

- Flutter
- Firebase Auth (Anonymous + optional upgrade later)
- Firestore
- Firebase Cloud Messaging
- SVG / Lottie (optional)

---

## Philosophy

This is not a reminder app.

It is a shared ritual between:
- The user
- Their caregivers
- A quiet digital companion

The app should feel patient, calm, and persistent — never demanding.
