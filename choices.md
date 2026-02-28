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

---

## Day 5 — Item CRUD

**Q: Should the edit item form include an "Origin" field (who assigned it)?**
→ **Yes** — show origin field on the edit item form.

**Q: When should the "weight" field (% contribution to final grade) appear?**
→ **Show weight field only when type is Test** — hidden for assignments and homework.

**Q: Should the grade field be editable on the create/edit item form?**
→ **Yes** — allow entering grade when creating/editing an item.

**Q: How should the user select which domain an item belongs to?**
→ **Dropdown picker** from the subject's domains.

**Q: How should users mark an item as complete?**
→ **Toggle button/checkbox on item detail screen**.

**Q: Delete UX for items?**
→ **Confirmation dialog** (same pattern as subjects).

**Q: Should the dashboard be wired to show real upcoming/overdue items?**
→ **Yes** — wire Upcoming and Trabalhos futuros sections with real item data.

**Q: Should tapping an item card on the dashboard navigate to its detail screen?**
→ **Yes** — tapping navigates to the item detail screen.

---

## Day 6 — Calendar & Future-Work View

**Q: Should tapping a day in the calendar filter the items list below to show only items due on that date?**
→ **Yes** — tapping a day shows items due on that date below the grid.

**Q: How should days with items be highlighted on the calendar grid?**
→ **Blue circle for today, blue text for days with items** (matches reference).

**Q: Should the month chips at the top be interactive?**
→ **Yes** — tapping a month chip switches the calendar to that month.

**Q: Should the "Trabalhos futuros" section show all future items or filter by selected month?**
→ **Filter future items to the selected month only**.

**Q: Should items in the "Trabalhos futuros" list be tappable?**
→ **No** — items in the calendar are display-only.

**Q: Should overdue item dates be shown in red?**
→ **Yes** — red text for overdue items, white for normal.

**Q: What info should each item in the "Trabalhos futuros" list show?**
→ **Item title, subject name, and due date** (dd/MM/yy).
