# TODO: recursively search through kicad project to remove any unused sheets
# https://forum.kicad.info/t/removal-delete-of-unused-hierarchical-sheets/63521

CURR_PATH=$(dirname "$0")

KICAD_PROJECT=$(find . -name *kicad_pro)
PROJECT_PATH=${KICAD_PROJECT[0]%.kicad_pro}
SCH_PATH="${PROJECT_PATH}.kicad_sch"

get_child_sheets() {
    child_sheets=$(grep -oP '"Sheetfile"."\K[^"]+' "$1")
    echo "$child_sheets"
}

sheets=$(get_child_sheets "$SCH_PATH")
echo "$sheets"