"""Abschnitt „Zwei frische Läufe vergleichen“: erst config-lauf-1.json und config-lauf-2.json ausführen."""
from pathlib import Path
import shutil

from analysis import compare_runs

print(compare_runs("outputs/lauf-1", "outputs/lauf-2"))

shutil.copytree("outputs/lauf-2", "outputs/lauf-3")
datei = Path("outputs/lauf-3/selected_prices.csv")
datei.write_text(datei.read_text().replace("100.00", "110.00"))
print(compare_runs("outputs/lauf-1", "outputs/lauf-3"))
