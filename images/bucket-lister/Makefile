VERSION ?= $(shell git rev-parse --short HEAD)
DOCKER_IMAGE = 489066871263.dkr.ecr.eu-west-1.amazonaws.com/bucket-lister:$(VERSION)

.DEFAULT_GOAL := help
help: ## List targets & descriptions
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the Docker image
	docker build -t $(DOCKER_IMAGE) .

.PHONY: run
run: ## Run the Docker container
	docker run -it -p 8080:8080 $(DOCKER_IMAGE)

.PHONY: push
push: ## Push the Docker image to a registry (requires you to be logged in)
	aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 489066871263.dkr.ecr.eu-west-1.amazonaws.com
	docker push $(DOCKER_IMAGE)
