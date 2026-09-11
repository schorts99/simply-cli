.PHONY: install ai-init ai-sync-dry-run ai-sync ai-doctor ai-status ai-create-design-doc help

install:
	@echo "Running installation script..."
	bash install.sh

ai-init:
	simply init ai

ai-create-design-doc:
	simply create design-doc

ai-sync-dry-run:
	simply sync ai --dry-run

ai-sync:
	simply sync ai --no-dry-run

ai-status:
	simply status

ai-doctor:
	simply doctor

help:
	@echo "=== simply CLI Make Targets ==="
	@echo ""
	@echo "Installation:"
	@echo "  make install                    → Install/upgrade simply CLI"
	@echo ""
	@echo "AI Config Management:"
	@echo "  make ai-init                    → Initialize .ai/ structure"
	@echo "  make ai-create-design-doc       → Create design-doc.md from template"
	@echo "  make ai-sync-dry-run            → Sync configs (dry run)"
	@echo "  make ai-sync                    → Sync configs (live run)"
	@echo "  make ai-status                  → Show current config status"
	@echo "  make ai-doctor                  → Run diagnostics and recommendations"
	@echo ""
	@echo "Example workflow:"
	@echo "  make install"
	@echo "  make ai-init"
	@echo "  make ai-sync"
