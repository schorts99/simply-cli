cmd_create_design_doc() {
  if [[ -f "$SIMPLY_DIR/design-doc.md" ]]; then
    cp "$SIMPLY_DIR/design-doc.md" ./design-doc.md
    log "✅ design-doc.md created from template"
  else
    error "Design doc template not found in ~/.simply/"
  fi
}
