.PHONY: install ai-init ai-sync ai-sync-both ai-doctor ai-status ai-create-design-doc help

install:
	@echo "Running installation script..."
	bash install.sh

ai-init:
	simply init ai

ai-create-design-doc:
	simply create design-doc

ai-sync:
	simply sync ai rules

ai-sync-global:
	simply sync ai rules --global

ai-sync-both:
	simply sync ai rules --both

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
	@echo "  make ai-sync                    → Sync configs (project only)"
	@echo "  make ai-sync-global             → Sync configs (global only)"
	@echo "  make ai-sync-both               → Sync to both project and global"
	@echo "  make ai-status                  → Show current config status"
	@echo "  make ai-doctor                  → Run diagnostics and recommendations"
	@echo ""
	@echo "Example workflow:"
	@echo "  make install"
	@echo "  make ai-init"
	@echo "  make ai-sync"
