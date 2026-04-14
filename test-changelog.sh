#!/bin/bash

MOCK_TAGS=(
  "v1.0.0"
  "v1.0.1-alpha"
  "v1.0.1-alpha1"
  "v1.0.1-alpha2"
  "v1.0.1-beta"
  "v1.0.1-beta1"
  "v1.0.1-beta2"
  "v1.0.1-rc1"
  "v1.0.1-rc2"
  "v1.0.1-rc"
  "v1.0.1"
)

# ─────────────────────────────────────────
# macOS-safe reverse: use 'tail -r' instead of 'tac'
# ─────────────────────────────────────────
reverse_lines() {
  tail -r
}

run_test() {
  local CURRENT_TAG="v1.0.2"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Testing: CURRENT_TAG = $CURRENT_TAG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # 1. Detect prefix
  if [[ "$CURRENT_TAG" == v* ]]; then
    TAG_FORMAT="vX.Y.Z"
    PREFIX="v"
  else
    TAG_FORMAT="X.Y.Z"
    PREFIX=""
  fi

  # 2. Detect stable vs pre-release
  if [[ "$CURRENT_TAG" =~ ^${PREFIX}[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IS_STABLE="true"
  else
    IS_STABLE="false"
  fi

  # 3. Mock git tag outputs (ascending = natural array order)
  mock_tags_asc() {
    printf '%s\n' "${MOCK_TAGS[@]}"
  }

  mock_tags_desc() {
    printf '%s\n' "${MOCK_TAGS[@]}" | reverse_lines
  }

  # 4. Resolve previous tag
  if [[ "$IS_STABLE" == "true" ]]; then
    # Stable → find previous stable only (skip all pre-releases)
    PREVIOUS_TAG=$(mock_tags_desc \
      | grep -E "^${PREFIX}[0-9]+\.[0-9]+\.[0-9]+$" \
      | grep -v "^${CURRENT_TAG}$" \
      | head -n 1)

  else
    # Pre-release → find the tag immediately before current in the list
    # Build filtered list first, then find current tag's index and pick i-1
    FILTERED=()
    while IFS= read -r line; do
      FILTERED+=("$line")
    done < <(mock_tags_asc \
      | grep -E "^${PREFIX}[0-9]+\.[0-9]+\.[0-9]+(-alpha[0-9]*|-beta[0-9]*|-rc[0-9]*)?$")

    PREVIOUS_TAG=""
    for i in "${!FILTERED[@]}"; do
      if [[ "${FILTERED[$i]}" == "$CURRENT_TAG" ]]; then
        if [[ $i -gt 0 ]]; then
          PREVIOUS_TAG="${FILTERED[$((i-1))]}"
        fi
        break
      fi
    done
  fi

  [[ -z "$PREVIOUS_TAG" ]] && PREVIOUS_TAG="(none — first tag or no match)"

  echo "  Tag Format : $TAG_FORMAT"
  echo "  Is Stable  : $IS_STABLE"
  echo "  Previous   : $PREVIOUS_TAG"

  # 5. Expected values
  case "$CURRENT_TAG" in
    "v1.0.0")         EXPECTED="(none — first tag or no match)" ;;
    "v1.0.1-alpha")   EXPECTED="v1.0.0" ;;
    "v1.0.1-alpha1")  EXPECTED="v1.0.1-alpha" ;;
    "v1.0.1-alpha2")  EXPECTED="v1.0.1-alpha1" ;;
    "v1.0.1-beta")    EXPECTED="v1.0.1-alpha2" ;;
    "v1.0.1-beta1")   EXPECTED="v1.0.1-beta" ;;
    "v1.0.1-beta2")   EXPECTED="v1.0.1-beta1" ;;
    "v1.0.1-rc1")     EXPECTED="v1.0.1-beta2" ;;
    "v1.0.1-rc2")     EXPECTED="v1.0.1-rc1" ;;
    "v1.0.1-rc")      EXPECTED="v1.0.1-rc2" ;;
    "v1.0.1")         EXPECTED="v1.0.0" ;;
    *) EXPECTED="unknown" ;;
  esac

  if [[ "$PREVIOUS_TAG" == "$EXPECTED" ]]; then
    echo "  Result     : ✅ PASS (expected: $EXPECTED)"
  else
    echo "  Result     : ❌ FAIL (expected: $EXPECTED, got: $PREVIOUS_TAG)"
  fi
}

# Run all
for tag in "${MOCK_TAGS[@]}"; do
  run_test "$tag"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All tests complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"