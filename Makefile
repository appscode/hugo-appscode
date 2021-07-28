.PHONY: run
run:
	@yqq w -i config.dev.yaml params.search_api_key --tag '!!str' $(GOOGLE_CUSTOM_SEARCH_API_KEY)
	hugo server --config=config.dev.yaml

PRODUCT ?=

.PHONY: docs
docs:
	hugo-tools docs-aggregator --shared  --product=$(PRODUCT)
	find ./data -name "*.json" -exec sed -i 's/https:\/\/cdn.appscode.com\/images/\/assets\/images/g' {} \;

.PHONY: docs-skip-assets
docs-skip-assets:
	hugo-tools docs-aggregator --skip-assets --shared  --product=$(PRODUCT)
	find ./data -name "*.json" -exec sed -i 's/https:\/\/cdn.appscode.com\/images/\/assets\/images/g' {} \;

.PHONY: assets
assets:
	hugo-tools docs-aggregator --only-assets
	find ./data -name "*.json" -exec sed -i 's/https:\/\/cdn.appscode.com\/images/\/assets\/images/g' {} \;

.PHONY: gen
gen:
	rm -rf public
	@yqq w -i config.dev.yaml params.search_api_key --tag '!!str' $(GOOGLE_CUSTOM_SEARCH_API_KEY)
	hugo --config=config.dev.yaml
	@yqq w -i config.dev.yaml params.search_api_key --tag '!!str' '_replace_'

.PHONY: qa
qa: gen
	firebase use default
	firebase deploy

.PHONY: gen-prod
gen-prod:
	rm -rf public
	@yqq w -i config.yaml params.search_api_key --tag '!!str' $(GOOGLE_CUSTOM_SEARCH_API_KEY)
	hugo --minify --config=config.yaml
	@yqq w -i config.yaml params.search_api_key --tag '!!str' '_replace_'

.PHONY: release
release: gen-prod
	firebase use prod
	firebase deploy
	firebase use default

.PHONY: check-links
check-links:
	liche -r public -d http://localhost:1313 -c 10 -p -l -x '^http://localhost:9090$$'

VERSION ?=

# https://stackoverflow.com/a/38982011/244009
.PHONY: set-version
set-version:
	@mv firebase.json firebase.bk.json
	@jq '(.hosting[] | .redirects[] | .destination) |= sub("\/products\/$(PRODUCT)\/.*\/"; "/products/$(PRODUCT)/$(VERSION)/"; "l")' firebase.bk.json > firebase.json

ASSETS_REPO_URL ?=
.PHONY: set-assets-repo
set-assets-repo:
	@mv data/config.json data/config.bk.json
	@jq '(.assets | .repoURL) |= "$(ASSETS_REPO_URL)"' data/config.bk.json > data/config.json
	@rm -rf data/config.bk.json
