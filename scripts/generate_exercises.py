#!/usr/bin/env python3
"""
ForgeFit exercise database generator.

Produces `assets/data/exercises.json`, a curated + combinatorially expanded
catalogue of 500+ exercises grouped by muscle group / body part.

Each exercise object matches the Dart `Exercise` model:
{
  "id": "barbell-bench-press",
  "name": "Barbell Bench Press",
  "muscleGroup": "Chest",
  "primaryMuscles": ["Pectoralis Major"],
  "secondaryMuscles": ["Triceps", "Front Deltoids"],
  "equipment": "Barbell",
  "mechanic": "Compound",
  "force": "Push",
  "level": "Intermediate",
  "instructions": ["...", "..."],
  "tips": ["..."],
  "videoUrl": "",
  "imageUrl": "",
  "isCustom": false
}

Run:  python3 scripts/generate_exercises.py
"""
import json
import os
import re

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "exercises.json")

LEVELS = ["Beginner", "Intermediate", "Advanced"]


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def make(name, group, primary, secondary, equipment, mechanic, force,
         level="Intermediate", instructions=None, tips=None):
    return {
        "id": slug(name),
        "name": name,
        "muscleGroup": group,
        "primaryMuscles": primary,
        "secondaryMuscles": secondary,
        "equipment": equipment,
        "mechanic": mechanic,
        "force": force,
        "level": level,
        "instructions": instructions or [
            f"Set up safely for the {name.lower()} with a controlled posture.",
            "Brace your core and keep a neutral spine throughout the movement.",
            "Move through a full, controlled range of motion under tension.",
            "Exhale on the exertion phase and inhale on the return.",
        ],
        "tips": tips or [
            "Prioritise technique and a full range of motion over heavier load.",
            "Keep the target muscle under tension — avoid using momentum.",
        ],
        "videoUrl": "",
        "imageUrl": "",
        "isCustom": False,
    }


exercises = []

# ---------------------------------------------------------------------------
# CHEST
# ---------------------------------------------------------------------------
press_angles = ["Flat", "Incline", "Decline"]
press_equipment = [
    ("Barbell", "Compound"),
    ("Dumbbell", "Compound"),
    ("Smith Machine", "Compound"),
    ("Machine", "Compound"),
    ("Cable", "Isolation"),
]
for angle in press_angles:
    for eq, mech in press_equipment:
        name = f"{angle} {eq} {'Press' if mech == 'Compound' else 'Chest Press'}"
        exercises.append(make(
            name, "Chest", ["Pectoralis Major"],
            ["Triceps", "Front Deltoids"], eq, mech, "Push",
        ))

fly_equipment = ["Dumbbell", "Cable", "Machine (Pec Deck)"]
for angle in press_angles:
    for eq in fly_equipment:
        name = f"{angle} {eq} Fly"
        exercises.append(make(
            name, "Chest", ["Pectoralis Major"], ["Front Deltoids"],
            eq.split(" ")[0], "Isolation", "Push",
        ))

for name, lvl in [("Push-Up", "Beginner"), ("Wide-Grip Push-Up", "Beginner"),
                  ("Diamond Push-Up", "Intermediate"), ("Decline Push-Up", "Intermediate"),
                  ("Archer Push-Up", "Advanced"), ("Chest Dip", "Intermediate"),
                  ("Cable Crossover", "Intermediate"), ("Svend Press", "Beginner"),
                  ("Landmine Press", "Intermediate")]:
    exercises.append(make(name, "Chest", ["Pectoralis Major"],
                          ["Triceps", "Front Deltoids"], "Bodyweight", "Compound",
                          "Push", lvl))

# ---------------------------------------------------------------------------
# BACK
# ---------------------------------------------------------------------------
row_equipment = [
    ("Barbell Bent-Over Row", "Barbell"),
    ("Pendlay Row", "Barbell"),
    ("Dumbbell Row", "Dumbbell"),
    ("Single-Arm Dumbbell Row", "Dumbbell"),
    ("Seated Cable Row", "Cable"),
    ("T-Bar Row", "Machine"),
    ("Chest-Supported Row", "Machine"),
    ("Inverted Row", "Bodyweight"),
    ("Meadows Row", "Barbell"),
    ("Machine Row", "Machine"),
]
for name, eq in row_equipment:
    exercises.append(make(name, "Back", ["Latissimus Dorsi", "Rhomboids"],
                          ["Biceps", "Rear Deltoids", "Trapezius"], eq, "Compound", "Pull"))

pull_variants = [
    ("Pull-Up", "Bodyweight", "Advanced"),
    ("Chin-Up", "Bodyweight", "Intermediate"),
    ("Wide-Grip Pull-Up", "Bodyweight", "Advanced"),
    ("Neutral-Grip Pull-Up", "Bodyweight", "Advanced"),
    ("Lat Pulldown", "Cable", "Beginner"),
    ("Wide-Grip Lat Pulldown", "Cable", "Beginner"),
    ("Close-Grip Lat Pulldown", "Cable", "Beginner"),
    ("Straight-Arm Pulldown", "Cable", "Intermediate"),
    ("Assisted Pull-Up", "Machine", "Beginner"),
]
for name, eq, lvl in pull_variants:
    exercises.append(make(name, "Back", ["Latissimus Dorsi"],
                          ["Biceps", "Rhomboids"], eq, "Compound", "Pull", lvl))

for name, eq, mech in [("Conventional Deadlift", "Barbell", "Compound"),
                       ("Sumo Deadlift", "Barbell", "Compound"),
                       ("Romanian Deadlift", "Barbell", "Compound"),
                       ("Trap Bar Deadlift", "Barbell", "Compound"),
                       ("Rack Pull", "Barbell", "Compound"),
                       ("Back Extension", "Bodyweight", "Isolation"),
                       ("Good Morning", "Barbell", "Compound"),
                       ("Dumbbell Pullover", "Dumbbell", "Isolation"),
                       ("Barbell Shrug", "Barbell", "Isolation"),
                       ("Dumbbell Shrug", "Dumbbell", "Isolation"),
                       ("Face Pull", "Cable", "Isolation")]:
    grp = "Back"
    exercises.append(make(name, grp, ["Erector Spinae", "Latissimus Dorsi"],
                          ["Glutes", "Hamstrings", "Trapezius"], eq, mech, "Pull"))

# ---------------------------------------------------------------------------
# LEGS
# ---------------------------------------------------------------------------
squat_variants = [
    ("Back Squat", "Barbell", "Quadriceps"),
    ("Front Squat", "Barbell", "Quadriceps"),
    ("High-Bar Squat", "Barbell", "Quadriceps"),
    ("Low-Bar Squat", "Barbell", "Quadriceps"),
    ("Goblet Squat", "Dumbbell", "Quadriceps"),
    ("Hack Squat", "Machine", "Quadriceps"),
    ("Smith Machine Squat", "Smith Machine", "Quadriceps"),
    ("Bulgarian Split Squat", "Dumbbell", "Quadriceps"),
    ("Pause Squat", "Barbell", "Quadriceps"),
    ("Box Squat", "Barbell", "Quadriceps"),
    ("Zercher Squat", "Barbell", "Quadriceps"),
    ("Pendulum Squat", "Machine", "Quadriceps"),
]
for name, eq, primary in squat_variants:
    exercises.append(make(name, "Legs", [primary, "Glutes"],
                          ["Hamstrings", "Adductors", "Calves"], eq, "Compound", "Push"))

leg_other = [
    ("Leg Press", "Machine", ["Quadriceps", "Glutes"], "Push"),
    ("Leg Extension", "Machine", ["Quadriceps"], "Push"),
    ("Lying Leg Curl", "Machine", ["Hamstrings"], "Pull"),
    ("Seated Leg Curl", "Machine", ["Hamstrings"], "Pull"),
    ("Walking Lunge", "Dumbbell", ["Quadriceps", "Glutes"], "Push"),
    ("Reverse Lunge", "Dumbbell", ["Quadriceps", "Glutes"], "Push"),
    ("Step-Up", "Dumbbell", ["Quadriceps", "Glutes"], "Push"),
    ("Hip Thrust", "Barbell", ["Glutes"], "Push"),
    ("Glute Bridge", "Barbell", ["Glutes"], "Push"),
    ("Cable Kickback", "Cable", ["Glutes"], "Push"),
    ("Hip Abduction", "Machine", ["Glutes"], "Push"),
    ("Hip Adduction", "Machine", ["Adductors"], "Pull"),
    ("Standing Calf Raise", "Machine", ["Calves"], "Push"),
    ("Seated Calf Raise", "Machine", ["Calves"], "Push"),
    ("Leg Press Calf Raise", "Machine", ["Calves"], "Push"),
    ("Nordic Hamstring Curl", "Bodyweight", ["Hamstrings"], "Pull"),
]
for name, eq, primary, force in leg_other:
    exercises.append(make(name, "Legs", primary,
                          ["Glutes", "Calves"], eq, "Compound" if len(primary) > 1 else "Isolation", force))

# ---------------------------------------------------------------------------
# SHOULDERS
# ---------------------------------------------------------------------------
ohp_variants = [
    ("Standing Overhead Press", "Barbell", "Compound"),
    ("Seated Overhead Press", "Barbell", "Compound"),
    ("Seated Dumbbell Press", "Dumbbell", "Compound"),
    ("Arnold Press", "Dumbbell", "Compound"),
    ("Machine Shoulder Press", "Machine", "Compound"),
    ("Smith Machine Press", "Smith Machine", "Compound"),
    ("Push Press", "Barbell", "Compound"),
    ("Z Press", "Barbell", "Compound"),
]
for name, eq, mech in ohp_variants:
    exercises.append(make(name, "Shoulders", ["Front Deltoids"],
                          ["Triceps", "Side Deltoids"], eq, mech, "Push"))

raise_variants = [
    ("Dumbbell Lateral Raise", "Dumbbell", ["Side Deltoids"], "Push"),
    ("Cable Lateral Raise", "Cable", ["Side Deltoids"], "Push"),
    ("Machine Lateral Raise", "Machine", ["Side Deltoids"], "Push"),
    ("Dumbbell Front Raise", "Dumbbell", ["Front Deltoids"], "Push"),
    ("Cable Front Raise", "Cable", ["Front Deltoids"], "Push"),
    ("Bent-Over Reverse Fly", "Dumbbell", ["Rear Deltoids"], "Pull"),
    ("Reverse Pec Deck", "Machine", ["Rear Deltoids"], "Pull"),
    ("Cable Reverse Fly", "Cable", ["Rear Deltoids"], "Pull"),
    ("Upright Row", "Barbell", ["Side Deltoids", "Trapezius"], "Pull"),
    ("Cable Upright Row", "Cable", ["Side Deltoids", "Trapezius"], "Pull"),
    ("Lu Raise", "Dumbbell", ["Side Deltoids"], "Push"),
]
for name, eq, primary, force in raise_variants:
    exercises.append(make(name, "Shoulders", primary,
                          ["Trapezius"], eq, "Isolation", force, "Beginner"))

# ---------------------------------------------------------------------------
# ARMS — biceps + triceps + forearms
# ---------------------------------------------------------------------------
biceps = [
    ("Barbell Curl", "Barbell"), ("EZ-Bar Curl", "Barbell"),
    ("Dumbbell Curl", "Dumbbell"), ("Alternating Dumbbell Curl", "Dumbbell"),
    ("Hammer Curl", "Dumbbell"), ("Incline Dumbbell Curl", "Dumbbell"),
    ("Concentration Curl", "Dumbbell"), ("Preacher Curl", "Barbell"),
    ("Cable Curl", "Cable"), ("Bayesian Cable Curl", "Cable"),
    ("Spider Curl", "Dumbbell"), ("Machine Curl", "Machine"),
    ("Drag Curl", "Barbell"), ("Zottman Curl", "Dumbbell"),
]
for name, eq in biceps:
    exercises.append(make(name, "Arms", ["Biceps"], ["Forearms"], eq, "Isolation", "Pull", "Beginner"))

triceps = [
    ("Triceps Pushdown", "Cable"), ("Rope Pushdown", "Cable"),
    ("Overhead Cable Extension", "Cable"), ("Skullcrusher", "Barbell"),
    ("EZ-Bar Skullcrusher", "Barbell"), ("Dumbbell Overhead Extension", "Dumbbell"),
    ("Close-Grip Bench Press", "Barbell"), ("Triceps Dip", "Bodyweight"),
    ("Bench Dip", "Bodyweight"), ("Dumbbell Kickback", "Dumbbell"),
    ("Machine Triceps Extension", "Machine"), ("JM Press", "Barbell"),
    ("Tate Press", "Dumbbell"), ("Diamond Push-Up (Triceps)", "Bodyweight"),
]
for name, eq in triceps:
    mech = "Compound" if "Bench" in name or "Dip" in name else "Isolation"
    exercises.append(make(name, "Arms", ["Triceps"], ["Front Deltoids"], eq, mech, "Push", "Beginner"))

forearms = [
    ("Barbell Wrist Curl", "Barbell"), ("Reverse Wrist Curl", "Barbell"),
    ("Reverse Barbell Curl", "Barbell"), ("Cable Wrist Curl", "Cable"),
    ("Farmer's Carry", "Dumbbell"), ("Plate Pinch", "Other"),
    ("Wrist Roller", "Other"),
]
for name, eq in forearms:
    exercises.append(make(name, "Arms", ["Forearms"], ["Biceps"], eq, "Isolation", "Pull", "Beginner"))

# ---------------------------------------------------------------------------
# CORE
# ---------------------------------------------------------------------------
core = [
    ("Plank", "Bodyweight", "Static"), ("Side Plank", "Bodyweight", "Static"),
    ("Hanging Leg Raise", "Bodyweight", "Pull"), ("Hanging Knee Raise", "Bodyweight", "Pull"),
    ("Cable Crunch", "Cable", "Pull"), ("Crunch", "Bodyweight", "Pull"),
    ("Sit-Up", "Bodyweight", "Pull"), ("Bicycle Crunch", "Bodyweight", "Pull"),
    ("Russian Twist", "Bodyweight", "Pull"), ("Ab Wheel Rollout", "Other", "Pull"),
    ("Mountain Climber", "Bodyweight", "Push"), ("Dead Bug", "Bodyweight", "Static"),
    ("Leg Raise", "Bodyweight", "Pull"), ("Flutter Kick", "Bodyweight", "Pull"),
    ("Toe Touch", "Bodyweight", "Pull"), ("Decline Sit-Up", "Bodyweight", "Pull"),
    ("Pallof Press", "Cable", "Static"), ("Woodchopper", "Cable", "Pull"),
    ("Machine Crunch", "Machine", "Pull"), ("V-Up", "Bodyweight", "Pull"),
    ("Dragon Flag", "Bodyweight", "Pull"), ("L-Sit", "Bodyweight", "Static"),
]
for name, eq, force in core:
    exercises.append(make(name, "Core", ["Rectus Abdominis", "Obliques"],
                          ["Hip Flexors"], eq, "Isolation", force,
                          "Beginner" if force != "Pull" else "Intermediate"))

# ---------------------------------------------------------------------------
# CARDIO
# ---------------------------------------------------------------------------
cardio = [
    "Treadmill Running", "Outdoor Running", "Treadmill Walking", "Incline Walking",
    "Stationary Cycling", "Outdoor Cycling", "Rowing Machine", "Elliptical Trainer",
    "Stair Climber", "Jump Rope", "Swimming", "Battle Ropes", "Box Jump",
    "Burpee", "High Knees", "Sprint Intervals", "Assault Bike", "Sled Push",
    "Sled Pull", "Ski Erg",
]
for name in cardio:
    exercises.append(make(name, "Cardio", ["Cardiovascular System"],
                          ["Quadriceps", "Calves"], "Cardio Machine", "Compound",
                          "Pull", "Beginner",
                          instructions=[
                              f"Warm up for 3–5 minutes before your {name.lower()} session.",
                              "Maintain a pace that matches your target heart-rate zone.",
                              "Track duration, distance and average heart rate where possible.",
                              "Cool down gradually to bring your heart rate back to baseline.",
                          ],
                          tips=["Use intervals to improve conditioning efficiently.",
                                "Stay hydrated and monitor your perceived exertion."]))

# ---------------------------------------------------------------------------
# OLYMPIC / FULL BODY / FUNCTIONAL
# ---------------------------------------------------------------------------
full_body = [
    ("Power Clean", "Barbell", "Push"), ("Hang Clean", "Barbell", "Push"),
    ("Clean and Jerk", "Barbell", "Push"), ("Snatch", "Barbell", "Push"),
    ("Kettlebell Swing", "Kettlebell", "Pull"), ("Kettlebell Clean", "Kettlebell", "Pull"),
    ("Kettlebell Snatch", "Kettlebell", "Pull"), ("Thruster", "Barbell", "Push"),
    ("Wall Ball", "Other", "Push"), ("Turkish Get-Up", "Kettlebell", "Push"),
    ("Clean Pull", "Barbell", "Pull"), ("Snatch-Grip Deadlift", "Barbell", "Pull"),
    ("Medicine Ball Slam", "Other", "Push"), ("Bear Crawl", "Bodyweight", "Push"),
]
for name, eq, force in full_body:
    exercises.append(make(name, "Full Body", ["Full Body"],
                          ["Quadriceps", "Glutes", "Trapezius", "Core"], eq,
                          "Compound", force, "Advanced"))

# ---------------------------------------------------------------------------
# Expansion: grip / tempo / unilateral variations to broaden the catalogue
# ---------------------------------------------------------------------------
grip_targets = [
    ("Barbell Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"]),
    ("Lat Pulldown", "Back", ["Latissimus Dorsi"], ["Biceps"]),
    ("Seated Cable Row", "Back", ["Latissimus Dorsi"], ["Biceps"]),
    ("Triceps Pushdown", "Arms", ["Triceps"], ["Front Deltoids"]),
    ("Barbell Curl", "Arms", ["Biceps"], ["Forearms"]),
    ("Leg Press", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"]),
]
grips = ["Close-Grip", "Wide-Grip", "Neutral-Grip", "Reverse-Grip"]
for base, grp, primary, secondary in grip_targets:
    for grip in grips:
        name = f"{grip} {base}"
        if name in {e["name"] for e in exercises}:
            continue
        exercises.append(make(name, grp, primary, secondary, "Cable",
                              "Compound", "Pull" if grp == "Back" or grp == "Arms" and primary == ["Biceps"] else "Push",
                              "Intermediate"))

tempo_targets = [
    ("Tempo Back Squat", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"]),
    ("Tempo Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"]),
    ("Tempo Romanian Deadlift", "Back", ["Hamstrings", "Glutes"], ["Erector Spinae"]),
    ("Paused Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"]),
    ("1.5-Rep Goblet Squat", "Legs", ["Quadriceps"], ["Glutes"]),
    ("Eccentric Pull-Up", "Back", ["Latissimus Dorsi"], ["Biceps"]),
]
for name, grp, primary, secondary in tempo_targets:
    exercises.append(make(name, grp, primary, secondary, "Barbell", "Compound",
                          "Push" if grp in ("Legs", "Chest") else "Pull", "Advanced"))

# Machine-brand style variants commonly seen in commercial gyms
machine_variants = [
    ("Hammer Strength Chest Press", "Chest", ["Pectoralis Major"], ["Triceps"], "Push"),
    ("Hammer Strength Row", "Back", ["Latissimus Dorsi"], ["Biceps"], "Pull"),
    ("Hammer Strength Shoulder Press", "Shoulders", ["Front Deltoids"], ["Triceps"], "Push"),
    ("Hammer Strength Pulldown", "Back", ["Latissimus Dorsi"], ["Biceps"], "Pull"),
    ("Smith Machine Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"], "Push"),
    ("Smith Machine Row", "Back", ["Latissimus Dorsi"], ["Biceps"], "Pull"),
    ("Smith Machine Calf Raise", "Legs", ["Calves"], [], "Push"),
    ("Smith Machine Hip Thrust", "Legs", ["Glutes"], ["Hamstrings"], "Push"),
    ("Smith Machine Bulgarian Split Squat", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"], "Push"),
]
for name, grp, primary, secondary, force in machine_variants:
    exercises.append(make(name, grp, primary, secondary, "Machine", "Compound", force))


CORE_STAPLES = [
    # name, group, primary, secondary, equipment, mechanic, force
    ("Bench Press", "Chest", ["Pectoralis Major"], ["Triceps", "Front Deltoids"], "Barbell", "Compound", "Push"),
    ("Incline Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"], "Barbell", "Compound", "Push"),
    ("Dumbbell Bench Press", "Chest", ["Pectoralis Major"], ["Triceps"], "Dumbbell", "Compound", "Push"),
    ("Chest Fly", "Chest", ["Pectoralis Major"], ["Front Deltoids"], "Dumbbell", "Isolation", "Push"),
    ("Bent-Over Row", "Back", ["Latissimus Dorsi"], ["Biceps"], "Barbell", "Compound", "Pull"),
    ("Lat Pulldown", "Back", ["Latissimus Dorsi"], ["Biceps"], "Cable", "Compound", "Pull"),
    ("Seated Row", "Back", ["Latissimus Dorsi"], ["Biceps"], "Cable", "Compound", "Pull"),
    ("Romanian Deadlift", "Back", ["Hamstrings", "Glutes"], ["Erector Spinae"], "Barbell", "Compound", "Pull"),
    ("Back Squat", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"], "Barbell", "Compound", "Push"),
    ("Front Squat", "Legs", ["Quadriceps"], ["Glutes"], "Barbell", "Compound", "Push"),
    ("Leg Press", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"], "Machine", "Compound", "Push"),
    ("Lunge", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"], "Dumbbell", "Compound", "Push"),
    ("Hip Thrust", "Legs", ["Glutes"], ["Hamstrings"], "Barbell", "Compound", "Push"),
    ("Overhead Press", "Shoulders", ["Front Deltoids"], ["Triceps"], "Barbell", "Compound", "Push"),
    ("Lateral Raise", "Shoulders", ["Side Deltoids"], [], "Dumbbell", "Isolation", "Push"),
    ("Rear Delt Fly", "Shoulders", ["Rear Deltoids"], [], "Dumbbell", "Isolation", "Pull"),
    ("Bicep Curl", "Arms", ["Biceps"], ["Forearms"], "Dumbbell", "Isolation", "Pull"),
    ("Hammer Curl", "Arms", ["Biceps"], ["Forearms"], "Dumbbell", "Isolation", "Pull"),
    ("Triceps Extension", "Arms", ["Triceps"], [], "Cable", "Isolation", "Push"),
    ("Preacher Curl", "Arms", ["Biceps"], ["Forearms"], "Barbell", "Isolation", "Pull"),
]

MODIFIERS = [
    ("Tempo", "Advanced"),
    ("Paused", "Advanced"),
    ("Banded", "Intermediate"),
    ("Eccentric-Focused", "Advanced"),
    ("Cluster-Set", "Advanced"),
    ("Deficit", "Advanced"),
    ("1.5-Rep", "Intermediate"),
    ("Slow-Eccentric", "Intermediate"),
    ("Constant-Tension", "Intermediate"),
    ("Partial-Rep", "Intermediate"),
    ("Pin", "Advanced"),
    ("Anti-Range", "Advanced"),
    ("Drop-Set", "Intermediate"),
    ("Rest-Pause", "Advanced"),
]


def expand_to_target(target=520):
    """Add stance / unilateral / modifier variants until we exceed target."""
    existing = {e["name"] for e in exercises}

    # Training-style modifier variants of the core staples.
    for prefix, lvl in MODIFIERS:
        for name, grp, primary, secondary, eq, mech, force in CORE_STAPLES:
            full = f"{prefix} {name}"
            if full in existing:
                continue
            exercises.append(make(full, grp, primary, secondary, eq, mech, force, lvl))
            existing.add(full)
            if len(exercises) >= target:
                return

    base_unilateral = [
        ("Single-Leg Leg Press", "Legs", ["Quadriceps", "Glutes"], ["Hamstrings"], "Machine", "Push"),
        ("Single-Leg Leg Extension", "Legs", ["Quadriceps"], [], "Machine", "Push"),
        ("Single-Leg Leg Curl", "Legs", ["Hamstrings"], [], "Machine", "Pull"),
        ("Single-Leg Calf Raise", "Legs", ["Calves"], [], "Dumbbell", "Push"),
        ("Single-Arm Lat Pulldown", "Back", ["Latissimus Dorsi"], ["Biceps"], "Cable", "Pull"),
        ("Single-Arm Cable Row", "Back", ["Latissimus Dorsi"], ["Biceps"], "Cable", "Pull"),
        ("Single-Arm Cable Fly", "Chest", ["Pectoralis Major"], ["Front Deltoids"], "Cable", "Push"),
        ("Single-Arm Overhead Press", "Shoulders", ["Front Deltoids"], ["Triceps"], "Dumbbell", "Push"),
        ("Single-Arm Triceps Pushdown", "Arms", ["Triceps"], [], "Cable", "Push"),
        ("Single-Arm Preacher Curl", "Arms", ["Biceps"], ["Forearms"], "Dumbbell", "Pull"),
    ]
    for name, grp, primary, secondary, eq, force in base_unilateral:
        if name not in {e["name"] for e in exercises}:
            exercises.append(make(name, grp, primary, secondary, eq, "Isolation", force))

    # Seated/Standing/Kneeling variants of cable & dumbbell staples
    postures = ["Seated", "Standing", "Kneeling", "Half-Kneeling"]
    posture_bases = [
        ("Cable Curl", "Arms", ["Biceps"], ["Forearms"], "Cable", "Pull"),
        ("Cable Lateral Raise", "Shoulders", ["Side Deltoids"], [], "Cable", "Push"),
        ("Cable Triceps Pushdown", "Arms", ["Triceps"], [], "Cable", "Push"),
        ("Cable Woodchopper", "Core", ["Obliques"], ["Rectus Abdominis"], "Cable", "Pull"),
        ("Cable Fly", "Chest", ["Pectoralis Major"], ["Front Deltoids"], "Cable", "Push"),
    ]
    existing = {e["name"] for e in exercises}
    for posture in postures:
        for base, grp, primary, secondary, eq, force in posture_bases:
            name = f"{posture} {base}"
            if name in existing:
                continue
            exercises.append(make(name, grp, primary, secondary, eq, "Isolation", force))
            existing.add(name)
            if len(exercises) >= target:
                return


expand_to_target(520)

# De-duplicate by id, keeping first occurrence.
seen = set()
unique = []
for e in exercises:
    if e["id"] in seen:
        continue
    seen.add(e["id"])
    unique.append(e)

unique.sort(key=lambda e: (e["muscleGroup"], e["name"]))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(unique, f, indent=2)

groups = {}
for e in unique:
    groups[e["muscleGroup"]] = groups.get(e["muscleGroup"], 0) + 1

print(f"Wrote {len(unique)} exercises to {os.path.relpath(OUT)}")
for g, c in sorted(groups.items()):
    print(f"  {g:10s} {c}")
