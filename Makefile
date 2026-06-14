# 太陽系 · 銀河系 單檔 HTML — 建置工具
#
# 工作流：
#   要編輯前先   make fmt   （prettier 展開成易讀，內嵌 three.js 也會展開）
#   編輯完成後   make min   （html-minifier-terser 壓回交付用單檔）
#
# minify 採「不改名、不 compress」（只去空白/註解），所以 fmt↔min 可無損來回，
# 變數名與程式結構都保留，方便下次再編輯。three.js bundle 為既有壓縮產物、不另處理。

HTML     := index.html
PORT     := 8000
PRETTIER := npx --yes prettier@3
MINIFIER := npx --yes html-minifier-terser@7

.DEFAULT_GOAL := help
.PHONY: help fmt min dev check serve open size backup clean

help: ## 顯示可用指令
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-8s\033[0m %s\n",$$1,$$2}'

fmt: backup ## prettier 展開 HTML（編輯前用）
	$(PRETTIER) --write $(HTML)
	@echo "→ 已格式化，可開始編輯 $(HTML)"

min: backup ## html-minifier-terser 壓縮 HTML（編輯後/交付用）
	$(MINIFIER) --config-file htmlmin.json -o $(HTML).tmp $(HTML)
	@mv $(HTML).tmp $(HTML)
	@$(MAKE) -s size

dev: fmt ## 等同 fmt（準備編輯）

check: ## 抽出內嵌 <script> 做 node --check 語法檢查
	@node -e 'const fs=require("fs"),cp=require("child_process");const h=fs.readFileSync("$(HTML)","utf8");let i=0;for(const m of h.matchAll(/<script(?: type="module")?>([\s\S]*?)<\/script>/g)){fs.writeFileSync("/tmp/_chk"+i+".js",m[1]);cp.execSync("node --check /tmp/_chk"+i+".js");i++}console.log("✓ "+i+" 個 script 語法 OK")'

serve: ## 本機 HTTP 伺服器（預設埠 8000）
	python3 -m http.server $(PORT)

open: ## 用預設瀏覽器開啟（已內嵌，file:// 可離線）
	open $(HTML)

size: ## 顯示檔案大小
	@echo "$(HTML): $$(du -h $(HTML) | cut -f1)"

backup: ## 變更前快照 .index.html.bak
	@cp $(HTML) .$(HTML).bak

clean: ## 移除備份與暫存檔
	@rm -f .$(HTML).bak $(HTML).tmp
	@echo "→ 已清理"
