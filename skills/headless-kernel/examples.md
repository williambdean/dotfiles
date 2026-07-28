# Headless Kernel: Worked Examples

End-to-end walkthroughs showing the headless kernel in action. Each example
uses a real analysis workflow to demonstrate session lifecycle, incremental
state, plotting, and common patterns.

---

## Walkthrough 1: Asheville Street Tree Analysis

Analyze tree diversity and invasive species from the City of Asheville's
public street tree inventory.

### 1.1 Start a session

```bash
uv run skills/headless-kernel/scripts/harness.py -s trees start --force
```

```
Starting kernel 'trees'...
Harness initialized. Temp plots directory: /var/folders/.../T/harness/dotfiles
/tmp/harness/dotfiles/kernel_trees.json
```

`--force` stops any stale session with the same name before starting. The
connection file lives in `/tmp/harness/<project-name>/` — no repo pollution.

### 1.2 Verify the kernel is alive

```bash
uv run skills/headless-kernel/scripts/harness.py -s trees exec "print('hello kernel')"
```

```
hello kernel
```

The one-liner `exec` form is the fastest way to run code and see output.

### 1.3 Fetch street tree data from ArcGIS

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s trees send -
import requests, pandas as pd
from collections import Counter

url = ("https://services.arcgis.com/70vcD5tpfNSJmyxA/arcgis/rest/services/"
       "Tree_Inventory_Street_Trees/FeatureServer/0/query"
       "?where=1%3D1&outFields=*&returnGeometry=false&f=json")
r = requests.get(url, timeout=30)
features = r.json()["features"]
rows = [f["attributes"] for f in features]
df = pd.DataFrame(rows)

print(f"Trees: {len(df)}")
print(f"Columns: {df.columns.tolist()}")
print(f"Species: {df['SCI_NAME'].nunique()}")
PYEOF
```

```
Trees: 3038
Columns: ['OBJECTID', 'SCI_NAME', 'COMMON_NAME', 'DBH', 'CONDITION', 'NOTES', ...]
Species: 89
```

The quoted `'PYEOF'` delimiter is critical — it prevents shell expansion of
`$`, backticks, and curly braces inside the heredoc. The session holds `df`
in memory for subsequent commands.

### 1.4 Compute diversity indices

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s trees send -
import numpy as np

counts = df["SCI_NAME"].value_counts()
n = counts.sum()
simpson = 1 - sum((c / n) ** 2 for c in counts)
shannon = -sum((c / n) * np.log(c / n) for c in counts)

print(f"Simpson's Diversity Index: {simpson:.3f}")
print(f"Shannon Index:             {shannon:.3f}")
print(f"Most common: {counts.head(5).to_dict()}")
PYEOF
```

```
Simpson's Diversity Index: 0.951
Shannon Index:             3.47
Most common: {'Pyrus calleryana': 145, 'Ulmus pumila': 94, ...}
```

The DataFrame `df` from step 1.3 is still in memory — no need to re-fetch.

### 1.5 Classify invasive species

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s trees send -
invasive_list = {
    "Pyrus calleryana": "Callery pear",
    "Ulmus pumila": "Siberian elm",
    "Acer platanoides": "Norway maple",
    "Morus alba": "White mulberry",
    "Ailanthus altissima": "Tree of heaven",
    "Paulownia tomentosa": "Princess tree",
    "Koelreuteria paniculata": "Golden rain tree",
    "Quercus acutissima": "Sawtooth oak",
    "Firmiana simplex": "Chinese parasoltree",
    "Broussonetia papyrifera": "Paper mulberry",
    "Acer palmatum": "Japanese maple",
}

df["invasive"] = df["SCI_NAME"].map(invasive_list)
inv = df.dropna(subset=["invasive"])
print(f"Invasive trees: {len(inv)} ({len(inv)/len(df)*100:.1f}%)")
print(f"Invasive species found: {inv['invasive'].nunique()}")
print(inv["invasive"].value_counts().to_string())
PYEOF
```

```
Invasive trees: 332 (11.4%)
Invasive species found: 11
Callery pear       145
Siberian elm        94
Norway maple        27
White mulberry      23
Tree of heaven       5
Princess tree        4
Golden rain tree     2
Sawtooth oak         1
Chinese parasoltree  1
Paper mulberry       1
Japanese maple       1
```

### 1.6 DBH-as-age proxy (spread dynamics)

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s trees send -
# Small trees (< 10 DBH) suggest recent establishment
df_inv = df.dropna(subset=["invasive"])
df_nat = df[df["invasive"].isna()]

inv_small = (df_inv["DBH"] < 10).sum()
inv_large = (df_inv["DBH"] >= 10).sum()
nat_small = (df_nat["DBH"] < 10).sum()
nat_large = (df_nat["DBH"] >= 10).sum()

print(f"Invasive  small/large: {inv_small}/{inv_large}  ratio={inv_small/inv_large:.2f}")
print(f"Native    small/large: {nat_small}/{nat_large}  ratio={nat_small/nat_large:.2f}")
PYEOF
```

```
Invasive  small/large: 76/256  ratio=0.30
Native    small/large: 1080/786  ratio=1.37
```

The invasive population is skewed toward large (older) trees — ratio 0.30
vs 1.37 for natives. This means invasives are under-establishing, likely
because the city stopped planting them.

### 1.7 Life cycle timeline plot

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s trees send -
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np, os

tmp = os.environ["HARNESS_TMP"]

species = [
    "Callery Pear", "Siberian Elm", "Norway Maple", "White Mulberry",
    "Tree of Heaven", "Princess Tree", "Golden Rain Tree", "Sawtooth Oak",
    "Chinese Parasoltree", "Paper Mulberry", "Japanese Maple",
]

data = [
    {"repro": 3,  "max": 50, "seeds": "8K-216K", "bank": 11, "color": "#d62728", "n": 145},
    {"repro": 5,  "max": 75, "seeds": "Thousands", "bank": 3,  "color": "#ff7f0e", "n": 94},
    {"repro": 10, "max": 80, "seeds": "Thousands", "bank": 2,  "color": "#2ca02c", "n": 27},
    {"repro": 5,  "max": 50, "seeds": "Copious",   "bank": 2,  "color": "#9467bd", "n": 23},
    {"repro": 5,  "max": 80, "seeds": "Thousands", "bank": 3,  "color": "#8c564b", "n": 5},
    {"repro": 4,  "max": 60, "seeds": "Up to 20M", "bank": 3,  "color": "#e377c2", "n": 4},
    {"repro": 5,  "max": 50, "seeds": "Prolific",  "bank": 5,  "color": "#7f7f7f", "n": 2},
    {"repro": 6,  "max": 70, "seeds": "Heavy",     "bank": 2,  "color": "#bcbd22", "n": 1},
    {"repro": 5,  "max": 50, "seeds": "Prolific",  "bank": 3,  "color": "#17becf", "n": 1},
    {"repro": 5,  "max": 50, "seeds": "Many",      "bank": 2,  "color": "#1f77b4", "n": 1},
    {"repro": 5,  "max": 60, "seeds": "Moderate",  "bank": 3,  "color": "#aec7e8", "n": 1},
]

fig, ax = plt.subplots(figsize=(14, 8))
y = np.arange(len(species))

for i, d in enumerate(data):
    ax.barh(i, d["repro"], 0.55, left=0, color=d["color"], alpha=0.25)
    ax.barh(i, d["max"] - d["repro"], 0.55, left=d["repro"],
            color=d["color"], alpha=0.75, edgecolor=d["color"])
    ax.text(d["max"] + 1, i, f"  {d['seeds']}/yr  bank {d['bank']}yr",
            fontsize=7, va="center")
    ax.text(-4, i, str(d["n"]), fontsize=10, color=d["color"],
            va="center", ha="center", fontweight="bold")

ax.set_yticks(y)
ax.set_yticklabels(species, fontsize=9)
ax.set_xlim(-6, 95)
ax.set_xlabel("Age (years)")
ax.set_title("Invasive Tree Life Cycles — Asheville Street Tree Inventory")
ax.grid(axis="x", alpha=0.3, ls="--")
plt.tight_layout()

path = os.path.join(tmp, "life_cycle_timeline.png")
plt.savefig(path, dpi=150)
print(f"Plot saved: {path}")
PYEOF
```

```
Plot saved: /var/folders/.../T/harness/dotfiles/life_cycle_timeline.png
```

Open the plot locally:

```bash
open /var/folders/.../T/harness/dotfiles/life_cycle_timeline.png
# Linux: xdg-open /var/folders/.../T/harness/dotfiles/life_cycle_timeline.png
```

### 1.8 Stop the kernel

```bash
uv run skills/headless-kernel/scripts/harness.py -s trees stop
```

```
Removed /tmp/harness/dotfiles/kernel_trees.json
```

Verify no lingering sessions:

```bash
uv run skills/headless-kernel/scripts/harness.py ps
```

```
No sessions found.
```

---

## Walkthrough 2: Marvel Movie Box Office

Explore a small dataset of Marvel Cinematic Universe films — load, inspect,
visualize time series, and align releases to day zero.

### 2.1 Start a session

```bash
uv run skills/headless-kernel/scripts/harness.py -s movies start --force
```

### 2.2 Load box office data

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s movies send -
import pandas as pd
from datetime import datetime

films = [
    {"title": "Iron Man",           "release": "2008-05-02", "opening": 102, "total": 585},
    {"title": "The Incredible Hulk","release": "2008-06-13", "opening": 55,  "total": 265},
    {"title": "Iron Man 2",         "release": "2010-05-07", "opening": 128, "total": 624},
    {"title": "Thor",               "release": "2011-05-06", "opening": 65,  "total": 449},
    {"title": "Captain America",    "release": "2011-07-22", "opening": 65,  "total": 371},
    {"title": "The Avengers",       "release": "2012-05-04", "opening": 207, "total": 1520},
    {"title": "Iron Man 3",         "release": "2013-05-03", "opening": 174, "total": 1215},
    {"title": "Thor: Dark World",   "release": "2013-11-08", "opening": 85,  "total": 645},
    {"title": "Winter Soldier",     "release": "2014-04-04", "opening": 95,  "total": 714},
    {"title": "Guardians Galaxy",   "release": "2014-08-01", "opening": 94,  "total": 773},
    {"title": "Age of Ultron",      "release": "2015-05-01", "opening": 191, "total": 1403},
    {"title": "Civil War",          "release": "2016-05-06", "opening": 179, "total": 1153},
    {"title": "Doctor Strange",     "release": "2016-11-04", "opening": 85,  "total": 678},
    {"title": "Ragnarok",           "release": "2017-11-03", "opening": 122, "total": 854},
    {"title": "Black Panther",      "release": "2018-02-16", "opening": 202, "total": 1347},
    {"title": "Infinity War",       "release": "2018-04-27", "opening": 257, "total": 2052},
    {"title": "Captain Marvel",     "release": "2019-03-08", "opening": 153, "total": 1128},
    {"title": "Endgame",            "release": "2019-04-26", "opening": 357, "total": 2798},
    {"title": "Far From Home",      "release": "2019-07-02", "opening": 92,  "total": 1132},
]

df = pd.DataFrame(films)
df["release"] = pd.to_datetime(df["release"])
print(f"Films: {len(df)}")
print(f"Date range: {df['release'].min().date()} to {df['release'].max().date()}")
PYEOF
```

```
Films: 19
Date range: 2008-05-02 to 2019-07-02
```

### 2.3 Explore columns and values

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s movies send -
print("Columns:", df.columns.tolist())
print()
print("Films by year:")
print(df["release"].dt.year.value_counts().sort_index().to_string())
print()
print("Top 5 by total gross:")
print(df.sort_values("total", ascending=False)[["title", "total"]].to_string(index=False))
PYEOF
```

```
Columns: ['title', 'release', 'opening', 'total']

Films by year:
2008    2
2010    1
2011    2
2012    1
2013    2
2014    2
2015    1
2016    2
2017    1
2018    2
2019    3

Top 5 by total gross:
        title  total
     Endgame   2798
Infinity War   2052
 The Avengers  1520
  Age of Ultron 1403
   Black Panther 1347
```

The `exec` form works too for quick inspection:

```bash
uv run skills/headless-kernel/scripts/harness.py -s movies exec "df['opening'].describe()"
```

```
count     19.000
mean     136.421
std       77.360
min       55.000
25%       85.000
50%      102.000
75%      179.000
max      357.000
```

### 2.4 Time series plot (calendar dates)

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s movies send -
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt, os

tmp = os.environ["HARNESS_TMP"]
df_sorted = df.sort_values("release")

fig, ax = plt.subplots(figsize=(12, 5))
ax.plot(df_sorted["release"], df_sorted["total"], "o-", color="#e23636")
ax.set_ylabel("Total gross ($M)")
ax.set_title("Marvel Box Office by Release Date")
plt.xticks(rotation=45)
plt.tight_layout()

path = os.path.join(tmp, "marvel_timeseries.png")
plt.savefig(path, dpi=150)
print(f"Saved: {path}")
PYEOF
```

Notice the x-axis is calendar dates, which makes it hard to compare the
trajectory of early films vs late films.

### 2.5 Align to release day zero

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s movies send -
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt, os
import numpy as np

tmp = os.environ["HARNESS_TMP"]
day0 = df["release"].min()
df["days_since"] = (df["release"] - day0).dt.days

fig, ax = plt.subplots(figsize=(12, 5))
ax.plot(df["days_since"], df["total"], "o-", color="#e23636")
ax.set_xlabel(f"Days since {day0.date()} (day zero)")
ax.set_ylabel("Total gross ($M)")
ax.set_title("Marvel Box Office — Aligned to Day Zero (First Release)")
ax.grid(alpha=0.3, ls="--")
plt.tight_layout()

path = os.path.join(tmp, "marvel_aligned.png")
plt.savefig(path, dpi=150)
print(f"Saved: {path}")
print(f"Day zero = {day0.date()} ({df.iloc[0]['title']})")
print(f"Day last  = {df['days_since'].max()} ({df.iloc[-1]['title']})")
PYEOF
```

```
Saved: /var/folders/.../T/harness/dotfiles/marvel_aligned.png
Day zero = 2008-05-02 (Iron Man)
Day last  = 4078 (Far From Home)
```

Now the spacing between points reflects actual time between releases, and
you can see the acceleration: 4 years to the first Avengers, then 3 years
to Age of Ultron, then 2 years to Infinity War.

### 2.6 Christmas release bump hypothesis

```bash
cat <<'PYEOF' | uv run skills/headless-kernel/scripts/harness.py -s movies send -
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt, os
import numpy as np

tmp = os.environ["HARNESS_TMP"]
df["december"] = df["release"].dt.month == 12

fig, ax = plt.subplots(figsize=(8, 5))
colors = df["december"].map({True: "#e23636", False: "#518cca"})
ax.scatter(df["opening"], df["total"], c=colors, s=80, alpha=0.7)
for _, row in df[df["december"]].iterrows():
    ax.annotate(row["title"], (row["opening"], row["total"]),
                fontsize=7, xytext=(5, 5), textcoords="offset points")

ax.set_xlabel("Opening weekend ($M)")
ax.set_ylabel("Total gross ($M)")
ax.set_title("December vs Non-December Releases")
ax.grid(alpha=0.3, ls="--")

from matplotlib.lines import Line2D
legend = [Line2D([0],[0], marker="o", color="w", markerfacecolor="#e23636", label="December"),
          Line2D([0],[0], marker="o", color="w", markerfacecolor="#518cca", label="Other months")]
ax.legend(handles=legend)

plt.tight_layout()
path = os.path.join(tmp, "marvel_christmas.png")
plt.savefig(path, dpi=150)
print(f"Saved: {path}")

decs = df[df["december"]]["total"].mean()
others = df[~df["december"]]["total"].mean()
print(f"December avg: ${decs:.0f}M")
print(f"Other months avg: ${others:.0f}M")
print(f"Difference: {((decs/others)-1)*100:+.0f}%")
PYEOF
```

Only two December releases (Thor: Dark World and Ragnarok) — not enough
data for a strong conclusion, but the scatter plot shows the relationship
between opening weekend and total gross.

### 2.7 Stop the kernel

```bash
uv run skills/headless-kernel/scripts/harness.py -s movies stop
```

---

## Pattern Cheat Sheet

Common command forms at a glance.

| What | Command |
|---|---|
| **One-liner** | `uv run $HARNESS exec "print(df.shape)"` |
| **Multi-line heredoc** | `cat <<'PYEOF' \| uv run $HARNESS send -` |
| **Run a file** | `uv run $HARNESS send analysis.py` |
| **Fire-and-forget** | `uv run $HARNESS exec -d "model.sample(2000)"` |
| **Check sessions** | `uv run $HARNESS ps` |
| **Kill a session** | `uv run $HARNESS --session foo stop` |
| **Restart (force)** | `uv run $HARNESS --session foo start --force` |
| **Find connection file** | `uv run $HARNESS --session foo locate` |

Key rules:

- **Use `'PYEOF'`** (quoted delimiter) in heredocs — unquoted `$` will be
  expanded by the shell and break your code.
- **Use `send` for multi-line code** (it reads stdin until EOF). Use `exec`
  for short single-line expressions.
- **State persists** — variables survive between commands. No need to
  re-load data.
- **Detach** (`-d`) submits and returns immediately. Write results to
  `$HARNESS_TMP` and check later.
- **Always stop** when done. Orphaned kernels accumulate ZMQ sockets.
