# Design: `/work-reconcile` — retrospektivní dorovnání výkazu

- **Datum:** 2026-07-07
- **Plugin:** `work` (nový skill)
- **Status:** návrh (schválený v brainstormingu)
- **Autor:** Petr Kratochvíl + Claude

## Účel

Na konci období (typicky měsíce) zrekonstruovat z reálné aktivity — **primárně z AI
chatů** — co se dělalo, porovnat to s tím, co už je ve výkazu (Toggl / ClickUp),
a nabídnout k **doplnění jen chybějící čas**. Po explicitním schválení každé
položky ji zapsat do cílového trackeru.

Řeší běžnou bolest: měsíční timesheet se doplňuje zpětně z paměti. Tady se
doplní z dat, ale **nikdy ne automaticky** — vždy `navrhni → potvrď → zapiš`.

### Klíčový rozdíl od `/work-standup`

`/work-standup` **reportuje** aktivitu; `/work-reconcile` ji **zapisuje** do
trackeru. Je to první skill v pluginu `work`, který něco zapisuje — proto je
princip `navrhni → potvrď → zapiš` závazný a zachovává bezpečnostního ducha
pluginu (standup explicitně nikdy neposílá nikam automaticky).

### Zařazení do `work` triády

| Skill | Otázka | Směr |
|-------|--------|------|
| `/work-start` | Co mám dělat? | dopředu |
| `/work-status` | Co se změnilo? | od rána |
| `/work-end` | Co jsem dnes zavřel? | dnes |
| `/work-standup` | Co jsem dělal od minula? | zpět (report) |
| **`/work-reconcile`** | **Co jsem dělal, ale nezapsal — a doplň to** | **zpět (zápis)** |

## Rozhodnutí z brainstormingu

| Téma | Rozhodnutí |
|------|-----------|
| Cíl | Doplnit **chybějící** výkazy (ne rekonstrukce od nuly) |
| Trvání | Odhad (gap-capping) jako default, ale **vždy potvrdit ručně** |
| Zdroje | Všech 5: AI chaty (pravda) + git + GitHub + Calendar + ClickUp |
| Cíl zápisu | Toggl **i** ClickUp podle configu (`sink.target`) |
| Telefonáty | Ručně přidat během review |
| Meetingy | Zapisují se jako výkaz (s filtrem na pracovní events) |
| Párování projektu | Podle repa/adresáře jako `/start`, fallback default |
| Detekce duplicit | Časový překryv + spočítat pokrytí (navrhnout jen chybějící rozdíl) |
| Umístění | Nový skill v pluginu `work` |

## Zdroje a jejich role

Dvě vrstvy. **AI chaty = pravda o čase i obsahu**; ostatní **konfirmují/doplňují**.

### Vrstva 1 — primární (nese čas)

**① AI session logy** — `~/.claude/projects/<enc-cesta>/*.jsonl`
- Formát ověřen: strojově čitelný JSONL, jeden soubor na session, per-projekt
  (dekódovaná cesta v názvu adresáře). Každý řádek má `timestamp` (ISO 8601,
  UTC), `type` (user/assistant/…), `sessionId`.
- Filtrovat na okno `[since, until]` podle `timestamp` řádků.
- **Trvání = gap-capping** (viz níže), ne konec−začátek.
- **Obsah/popis:** z `ai-title` záznamu (vygenerovaný titulek session) + prvních
  pár user promptů.
- **Projekt:** z názvu adresáře session (dekódovaná cesta → repo) → párování
  jako `/start`.

**② Google Calendar** — `mcp__claude_ai_Google_Calendar__list_events` v okně
- Každý event = start + délka → přímý kandidát na výkaz.
- **Filtr pracovních:** vyřadit celodenní, „declined" účast, a volitelně klíčová
  slova (`exclude_keywords`, default oběd/lunch/dovolená). Konfigurovatelné.

**③ Telefonáty** — žádný MCP zdroj; skill se během review zeptá a přidá ručně
(start, délka, projekt, popis).

### Vrstva 2 — konfirmační (obohatí/rozšíří, samy čas nenesou)

- **④ Git commity** (lokálně) — `git log` v okně; ukotví AI session k repu,
  doplní práci bez session.
- **⑤ GitHub** — PR / reviews / merge (reviews často nezanechají commit).
  `mcp__github__` (už čte `/work-standup`).
- **⑥ ClickUp** — aktivita v úkolech + komentáře; firemní kontext.
  `mcp__plugin_ntit-common_clickup__`.

### Jak vrstvy spolupracují

```
AI session (14:00–15:30, "fix auth bug", repo X)   ← primární blok, 90 min
   └─ potvrzeno: 3 commity v repu X v tom okně      ← git konfirmuje
   └─ potvrzeno: PR #42 merged                       ← GitHub konfirmuje
Meeting 10:00–11:00 "Sprint planning"              ← samostatný blok, 60 min
Commit 22:15 v repu Y, ale ŽÁDNÁ session           ← jen git → blok bez odhadu času
                                                       (uživatel doplní ručně)
```

**Anti-dvojí-započítání (závazné):** commit/PR spadající do časového okna AI
session se **nepočítá zvlášť** — je součástí té session (jen zvýší jistotu a
obohatí popis). Jen když existuje pouze konfirmační stopa (commit bez session),
vznikne **blok bez odhadu času** → uživatel doplní trvání ručně.

**Dostupnost zdroje** se ověří `ToolSearch`em (jako `/work-standup`, viz jeho
step 4 a `/work-setup` detekční tabulka); chybějící MCP → warning + skip, ne pád.

## Odhad trvání (gap-capping)

Odhad je **vždy jen výchozí hodnota k ruční úpravě** — nikdy se nezapíše bez
potvrzení. Řeší past: session nechaná otevřená přes noc má klidně 31 h wall-clock
(ověřeno na reálném logu), což není odpracovaný čas.

### Algoritmus pro AI session

```
Seřaď timestampy zpráv v session vzestupně.
duration = 0
pro každou sousední dvojici (t[i], t[i+1]):
    gap = t[i+1] − t[i]
    if gap <= GAP_THRESHOLD:   duration += gap        # aktivní práce
    else:                       duration += EDGE_PAD   # přestávka → jen malý „doběh"
duration += EDGE_PAD   # poslední zpráva → user ještě chvíli pracoval
```

- **`GAP_THRESHOLD`** (default **15 min**, konfig.): pauza delší = přestávka.
- **`EDGE_PAD`** (default **2 min**): doběh za každou přestávkou a za koncem
  session. Noční mezera = jedna velká mezera → započte se jen 1× EDGE_PAD, ne
  8 h. Tím padá 31h problém.

### Zaokrouhlení

- Výsledek zaokrouhlit na **`round_to_min`** (default **5 min**).
- **`min_block_min`** (default **5 min**): kratší session ignorovat jako šum.

### Meetingy (Calendar)

Trvání = **přesně délka eventu** (start→end). Žádný gap-capping — meeting je
souvislý.

### Bloky bez session (jen commit / jen PR)

**Žádný automatický odhad** — trvání = `?`, uživatel doplní ručně v review.

### Transparentnost (výkaz = fakturační podklad)

Každý návrh v review nese **značku původu odhadu**:

| Značka | Význam |
|--------|--------|
| `~90m (AI, gap-capped)` | odhad z chatu — **odhad**, uprav dle potřeby |
| `60m (kalendář)` | přesná délka meetingu — spolehlivé |
| `? (jen commit)` | čas nutno doplnit ručně |

## Diff proti výkazu (detekce duplicit)

Jádro toho, proč skill „doplňuje", ne „duplikuje". Volba: **časový překryv +
spočítat pokrytí** → navrhnout jen chybějící rozdíl.

### Postup

1. **Načti existující výkaz** za okno `[since, until]` přes MCP — **jen z těch
   trackerů, které jsou v `sink.target`** (číst busy-map z ClickUpu nemá smysl,
   když se zapisuje jen do Togglu). Toggl přes `get_time_entries`, ClickUp přes
   jeho time-entries endpoint. Každý záznam má start, konec, projekt.
2. **Postav „busy map"** per projekt+den — sjednocené vykázané intervaly.
3. **Pro každý kandidátský blok** spočítej překryv s busy map na stejném
   projektu+dni:
   ```
   overlap  = kolik z bloku [start, end] už spadá do vykázaných intervalů
   coverage = overlap / délka_bloku
   ```
4. **Rozhodni podle pokrytí** (prahy konfigurovatelné):

   | Pokrytí | Akce | Značka v review |
   |---------|------|-----------------|
   | `≥ coverage_covered` (0.9, COVERED) | **nenavrhovat** | skryto, jen v souhrnu |
   | `coverage_missing`–`coverage_covered` (0.1–0.9, PARTIAL) | navrhnout **jen rozdíl** | `~35m (doplněk k 55m)` |
   | `< coverage_missing` (0.1, MISSING) | navrhnout **celý blok** | `~90m (chybí)` |

5. **Zbytkový čas u PARTIAL:** návrh = `délka_bloku − overlap`, zaokrouhleno.
   Popis a projekt zdědí z bloku.

### Proč překryv, ne přesná shoda

Ruční Toggl entry se nikdy nekryje 1:1 s AI session. Překryv na projektu+dni je
robustní: pozná „tady už něco vykázáno je", i když hranice nesedí na minuty.

### Hraniční případy

- **Projekt se nenapáruje** → blok nejde porovnat s busy map → `⚠ projekt?`,
  doplnit v review, pak dopočítat pokrytí.
- **Existující entry bez projektu** (Toggl to dovolí) → počítat do „obecné"
  busy map dne.
- **Blok přes půlnoc** (23:30→00:45) → rozdělit na dva dny kvůli per-den
  porovnání.

## Průběh skillu, review a zápis

### End-to-end tok

```
/work-reconcile [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--project <name>] [--dry-run]

1. Config     → načti ~/.claude/plugins/work/config.json (jako standup);
                fallback na session-tracker config pro Toggl klíč/sink.
2. Okno       → --since/--until, default: minulý kalendářní měsíc; echni rozsah.
3. Fetch (║)  → všech 5 zdrojů PARALELNĚ (jeden message, víc tool_use);
                nedostupný MCP → warning + skip.
4. Bloky      → z primárních zdrojů posbírej kandidátské bloky, přiřaď projekt
                (repo/dir jako /start), spočti trvání.
5. Anti-dvojí → commit/PR spadající do AI session slouč do ní.
6. Diff       → busy map z existujícího výkazu, coverage, zahoď COVERED.
7. REVIEW     → interaktivní schválení (viz níže).
8. Zápis      → jen schválené, bezpečně (viz níže).
9. Souhrn     → co zapsáno / přeskočeno / kam; per projekt součty.
```

### Review (krok 7) — srdce „potvrď"

Nejdřív **přehledová tabulka** návrhů, seskupená po projektech+dnech:

```
Projekt X — po 2026-06-02
  ~90m  fix auth bug          (AI, gap-capped)  [git ✓ 3c, PR#42 ✓]
   35m  code review           (doplněk k 25m)   [GitHub ✓]
   60m  Sprint planning        (kalendář)
   ?    hotfix deploy          (jen commit — DOPLŇ ČAS)
Souhrn: 12 návrhů (8.5 h) · 5 pokrytých skryto · 1 bez času
```

Pak **schvalování** přes `AskUserQuestion` (položek může být hodně → dávkově):
- **Na projekt/den:** „Zapsat tuhle skupinu? [Vše / Vybrat / Přeskočit / Upravit]".
- **Upravit** → přepsat trvání (a případně projekt/popis) u konkrétní položky.
  Položky s `?` (bez času) **nelze schválit bez zadání času** — vynutí se.
- **Přidat telefonát** → volba „+ přidat ruční položku" (start, délka, projekt,
  popis).

Nic mimo explicitně schválené se nezapíše. `--dry-run` = projde vše až po review
a **jen vypíše**, nezapíše.

### Zápis (krok 8) — bezpečně, přebírá vzor z `/log-entry`

- **Sink dle configu:** Toggl (`POST .../time_entries`) nebo ClickUp
  (`clickup_add_time_entry`), volitelně obojí (`sink.target: both`).
- **Bezpečnost API klíče:** klíč **nikdy v argv** — čte se do shell proměnné a
  předává přes stdin/header (out of `ps` a transcriptů). Vzor, který už
  `/log-entry` má.
- **Čas:** převody přes `date` (žádná TZ aritmetika „z hlavy"), okno se echuje
  v lokálním čase.
- **billable/tagy:** z configu (default `billable=true`).
- **Idempotence:** zapsané entry dostane tag `sink.reconciled_tag` (default
  `reconciled`) → opakovaný běh je pozná a přeskočí, i kdyby busy-map překryv
  selhal.
- **Chyba zápisu položky** → nezhroutit celek: zaznamenat, pokračovat, nahlásit
  v souhrnu.

## Config (rozšíření `~/.claude/plugins/work/config.json`)

Nový skill přidá vlastní blok `reconcile`, zbytek `work` configu (sdílené
`sources`) nechá být:

```json
{
  "sources": { "...": "sdíleno se /work-standup (toggl, github, clickup, calendar)" },
  "reconcile": {
    "default_window": "last_month",
    "gap_threshold_min": 15,
    "edge_pad_min": 2,
    "round_to_min": 5,
    "min_block_min": 5,
    "coverage_covered": 0.9,
    "coverage_missing": 0.1,
    "ai_sessions": {
      "enabled": true,
      "projects_dir": "~/.claude/projects"
    },
    "calendar": {
      "as_work": true,
      "exclude_all_day": true,
      "exclude_declined": true,
      "exclude_keywords": ["oběd", "lunch", "dovolená"]
    },
    "sink": {
      "target": "toggl",
      "billable": true,
      "reconciled_tag": "reconciled"
    }
  }
}
```

`/work-setup` dostane volitelný krok „nastavit reconcile" (jinak defaulty výše).
**Zpětná kompatibilita:** chybějící `reconcile` blok → skill použije defaulty,
nespadne.

## Error handling

| Situace | Chování |
|---------|---------|
| Chybí `work` config | Stop: „Spusť `/work-setup`." |
| MCP zdroj nedostupný | Warning + skip zdroje, běž dál |
| Žádný sink klíč (Toggl ani ClickUp) | Po review nabídni **export** (markdown/CSV), nezapisuj |
| Projekt se nenapáruje | `⚠ projekt?`, doplnit v review, jinak blok přeskočit |
| Prázdné okno | „Za období není nezapsaná aktivita." — nepolstrovat |
| Zápis položky selže | Zaloguj, pokračuj, nahlas v souhrnu |
| Session přes noc (velká mezera) | Gap-capping ji ořízne — hlavní pojistka |

## Testování

Skilly nejsou spustitelný kód → **manuální scénářové ověření** (jako ostatní
`work` skilly). Checklist scénářů (do PR):

1. `--dry-run` na reálném minulém měsíci → rozumnost odhadů a značek původu.
2. Session přes noc → ověřit, že se nezapočte 31 h.
3. Částečně vykázaný den → PARTIAL navrhne jen rozdíl.
4. COVERED den → nic se nenavrhne.
5. Commit bez session → `?` a vynucení ručního času.
6. Idempotence → 2× běh, druhý nic nezapíše (tag `reconciled`).
7. Chybějící MCP (např. Calendar) → warning + graceful pokračování.

## Dopady na existující soubory

- `plugins/work/skills/reconcile/SKILL.md` — nový skill.
- `plugins/work/skills/setup/SKILL.md` — volitelný krok konfigurace `reconcile`.
- `plugins/work/skills/standup/SKILL.md` — přidat řádek `/work-reconcile` do
  tabulky triády.
- `plugins/work/CLAUDE.md` — tabulka skillů + config dokumentace.
- `plugins/work/README.md` — popis nového skillu.
- Bump verze `work` **minor → 0.3.0** (nová feature) na 3 místech dle konvence
  (`plugin.json`, skill frontmatter, `marketplace.json`).

## YAGNI / mimo rozsah (v1)

- Automatický odhad času u bloků bez session (jen commit/PR) — zůstává ruční.
- Čtení systémové historie hovorů (macOS/iOS call log) — nespolehlivé.
- Per-source filtr UI v `/work-setup` nad rámec defaultů — ladí se v JSON.
- Rekonstrukce výkazu od nuly (ignorování existujícího) — mimo cíl.
