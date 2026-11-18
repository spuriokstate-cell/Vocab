# Children's Privacy and App Store Checklist

## How the app protects privacy (by design)

- **No accounts.** No sign-up, no email, no login for children.
- **No internet needed.** The app makes no network requests: no Firebase, analytics, ads or tracking SDKs.
- **Local only.** Progress is saved with `shared_preferences` on the device. Only a first name or nickname and an emoji avatar are stored, and both are optional.
- **No permissions requested.** No camera, microphone, location or contacts. Android only declares a `<queries>` entry so the app can find the phone's built-in text-to-speech voice.
- **No external links for children.** There are no web links anywhere in the child area.
- **Parent gate.** Settings, profiles, export and reset sit behind a grown-up multiplication question.
- **No manipulative rewards.** Stars and badges are never taken away. There are no timers that punish slowness, no leaderboards, no purchases and no ads.
- **Export.** The CSV report is written only to the device (and the clipboard) when a parent asks for it.

## Store checklist

These are steps still to do before publishing. Store rules change, so please re-check each store's current policy pages before you submit; this list is not a legal review.

**Google Play (Families policy)**
- [ ] Target audience: ages 6–8 (and 9–12 if you like) in Play Console.
- [ ] Data safety form: "No data collected" and "No data shared".
- [ ] Privacy policy URL (required even when nothing is collected; a simple page saying so is enough).
- [ ] Content rating questionnaire (IARC).
- [ ] Confirm that no third-party SDKs that aren't approved for children are added later.

**Apple App Store (Kids category)**
- [ ] Kids category, age band 6–8.
- [ ] App Privacy: "Data Not Collected".
- [ ] Privacy policy URL.
- [ ] Parental gate before any purchase or link (already in place for the parent area).
- [ ] No third-party analytics or advertising (none included).

**Microsoft Store**
- [ ] Age rating through IARC.
- [ ] Privacy policy URL (needed if the app ever accesses the internet; it doesn't today).
- [ ] MSIX package signed for submission.

**Other things to know**
- **US (COPPA) and EU/UK (GDPR-K, Age Appropriate Design Code):** because the app collects no personal data and sends nothing off the device, most obligations don't apply. Check again if you ever add cloud sync.
- **Firebase:** an earlier version of this app used Firebase for editing words online. This version is offline-first as requested. If cloud sync is added back later, update the privacy policy and store forms first.
