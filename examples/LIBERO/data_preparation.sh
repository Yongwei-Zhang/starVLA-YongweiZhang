#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   export DEST=/path/to/dir && bash examples/LIBERO/data_preparation.sh
# or
#   bash examples/LIBERO/data_preparation.sh /path/to/dir

DEST="${DEST:-${1:-}}"
if [[ -z "${DEST}" ]]; then
  echo "ERROR: DEST is not set."
  echo "  export DEST=/path/to/dir && bash examples/LIBERO/data_preparation.sh"
  echo "  or: bash examples/LIBERO/data_preparation.sh /path/to/dir"
  exit 1
fi

CUR="$(pwd)"
mkdir -p "$DEST"

python -m pip install -U "huggingface-hub==0.35.3"

for repo in \
  IPEC-COMMUNITY/libero_spatial_no_noops_1.0.0_lerobot \
  IPEC-COMMUNITY/libero_object_no_noops_1.0.0_lerobot \
  IPEC-COMMUNITY/libero_goal_no_noops_1.0.0_lerobot \
  IPEC-COMMUNITY/libero_10_no_noops_1.0.0_lerobot
do
  hf download "$repo" --repo-type dataset --local-dir "$DEST/libero/${repo##*/}"
done

hf download "StarVLA/LLaVA-OneVision-COCO" --repo-type dataset --local-dir "$DEST/LLaVA-OneVision-COCO"
unzip -- "$DEST/LLaVA-OneVision-COCO/sharegpt4v_coco.zip" -d "$DEST/LLaVA-OneVision-COCO/"

mkdir -p "$CUR/playground/Datasets"

# Create symlinks only if the target path does not exist (avoids "File exists" when
# LEROBOT_LIBERO_DATA or LEROBOT_LIBERO_DATA/libero already exists as a directory).
LEROBOT_DATA="$CUR/playground/Datasets/LEROBOT_LIBERO_DATA"
if [[ -e "$LEROBOT_DATA" ]]; then
  if [[ -L "$LEROBOT_DATA" ]]; then
    echo "Symlink already exists: $LEROBOT_DATA -> $(readlink "$LEROBOT_DATA")"
  else
    echo "Directory already exists: $LEROBOT_DATA (skip creating symlink; ensure data_root_dir points to this or $LEROBOT_DATA/libero)"
  fi
else
  ln -s "$DEST/libero" "$LEROBOT_DATA"
fi

LLAVA_DATA="$CUR/playground/Datasets/LLaVA-OneVision-COCO"
if [[ -e "$LLAVA_DATA" ]]; then
  if [[ -L "$LLAVA_DATA" ]]; then
    echo "Symlink already exists: $LLAVA_DATA -> $(readlink "$LLAVA_DATA")"
  else
    echo "Directory already exists: $LLAVA_DATA (skip creating symlink)"
  fi
else
  ln -s "$DEST/LLaVA-OneVision-COCO" "$LLAVA_DATA"
fi

## move modality (support both LEROBOT_LIBERO_DATA/libero_* and LEROBOT_LIBERO_DATA/libero/libero_*)
for subset in libero_10_no_noops_1.0.0_lerobot libero_goal_no_noops_1.0.0_lerobot libero_object_no_noops_1.0.0_lerobot libero_spatial_no_noops_1.0.0_lerobot; do
  for base in "$LEROBOT_DATA" "$LEROBOT_DATA/libero"; do
    meta_dir="$base/$subset/meta"
    if [[ -d "$base/$subset" ]]; then
      mkdir -p "$meta_dir"
      cp "$CUR/examples/LIBERO/train_files/modality.json" "$meta_dir"
      break
    fi
  done
done
