---
name: lean-methodology-check
enabled: true
event: prompt
pattern: (new feature|new project|build a|create a|design a|implement a|add a feature|phase \d|architecture|platform|system design|scaffold)
action: warn
---

**Lean Methodology Gate — before building, answer these:**

1. **Hypothesis:** What specific user behavior are you predicting? (Not "this will be useful" — a falsifiable statement)
2. **MVP:** What's the minimum version that tests the hypothesis? (If it's more than 2 weeks of solo work, it's not an MVP)
3. **First 5 users:** Name 5 real humans who will use this in 30 days. (Not personas — actual people)
4. **Success metric:** How will you know it worked? (Define before writing code)
5. **Pivot trigger:** At what point do you stop and change direction?

If you can't answer all five, you're building for your portfolio, not for users. That's a valid choice — make it conscious.
