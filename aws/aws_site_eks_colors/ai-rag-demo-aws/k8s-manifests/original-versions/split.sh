#!/bin/bash

INPUT_FILE="manifests.yaml"
TMP_DIR="./split_manifests"
mkdir -p "$TMP_DIR"

# Split using awk, each document to a temporary file
awk -v tmp_dir="$TMP_DIR" '
  BEGIN {doc=0; filename=sprintf("%s/manifest_%03d.yaml", tmp_dir, doc)}
  /^---[[:space:]]*$/ {
    doc++;
    filename=sprintf("%s/manifest_%03d.yaml", tmp_dir, doc);
    next;
  }
  { print >> filename }
' "$INPUT_FILE"

# Process each file
for file in "$TMP_DIR"/manifest_*.yaml; do
  # Skip empty files
  if [[ ! -s "$file" ]]; then
    rm -f "$file"
    continue
  fi

  # Use yq to extract kind and metadata.name
  kind=$(yq e '.kind' "$file")
  name=$(yq e '.metadata.name' "$file")

  if [[ "$kind" == "null" || "$name" == "null" ]]; then
    echo "Skipping $file: missing kind or metadata.name"
    continue
  fi

  case "$kind" in
    Deployment)
      output_file="${name}.yaml"
      ;;
    Service)
      output_file="${name}-svc.yaml"
      ;;
    *)
      echo "Skipping $file: unsupported kind '$kind'"
      continue
      ;;
  esac

  mv "$file" "./$output_file"
  echo "Created $output_file"
done

# Clean up
rmdir "$TMP_DIR" 2>/dev/null
