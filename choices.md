# ScholarFlux — Design Choices

## Day 1–3 (from plan.md Q&A)

**Q1: Storage/sync approach?**
→ **Local-first only** — no cloud sync in MVP; repository abstraction keeps it pluggable.

**Q2: Authentication?**
→ **No authentication** — no Firebase Auth needed.

**Q3: Attachments?**
→ **Attachments deferred** — items are text-only for MVP.

**Q4: State management?**
→ **Riverpod** — chosen for state management.

**Q5: Internationalization?**
→ **English only** — no i18n in MVP.

**Q6: Bundle ID?**
→ **com.scholarflux.app**

---

## Day 4 — Subject CRUD

**Q: Should subjects include domains (grading categories)?**
→ **Include domains in Day 4** — subjects need domain fields to match the reference image.

**Q: How should domains work within a subject?**
→ **Simple**: each domain has a name (e.g. "D1") and a weight percentage; grades per domain are calculated from items.

**Q: Should a grade field be added to the Item model now?**
→ **Yes** — add a grade (double?) field to Item now in Day 4, since the subject's "Média" depends on item grades.

**Q: How should the subject "Média" (average) be calculated?**
→ **Weighted average of domain averages** (domain avg × domain weight%) — matches the reference.

**Q: Should items be linked to a specific domain within a subject?**
→ **Yes** — each item should be assigned to a specific domain of its subject, so grades flow into the correct domain average.

**Q: Delete UX for subjects?**
→ **Delete confirmation dialog** before removing a subject (cascades to items).

**Q: Create/edit subject form style?**
→ **Full-screen page** with back navigation (matches the reference).

**Q: Grading scale?**
→ **User-configurable per subject** (e.g. 0–20, 0–100, 0–10).
