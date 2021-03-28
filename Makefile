# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
.PHONY: docs help test

# Use bash for inline if-statements in arch_patch target
SHELL:=bash
ARCH:=$(shell uname -m)
OWNER:=romainx
IMAGE:=hello-gradle

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1

help:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo "jupyter/docker-stacks"
	@echo "====================="
	@echo "Replace % with a stack directory name (e.g., make build/minimal-notebook)"
	@echo
	@grep -E '^[a-zA-Z0-9_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: DARGS?=
build: ## build the latest image for a stack
	docker build $(DARGS) --rm --force-rm -t $(OWNER)/$(IMAGE):latest .
	@echo -n "Built image size: "
	@docker images $(OWNER)/$(IMAGE):latest --format "{{.Size}}"


cont-clean-all: cont-stop-all cont-rm-all ## clean all containers (stop + rm)

cont-stop-all: ## stop all containers
	@echo "Stopping all containers ..."
	-docker stop -t0 $(shell docker ps -a -q) 2> /dev/null

cont-rm-all: ## remove all containers
	@echo "Removing all containers ..."
	-docker rm --force $(shell docker ps -a -q) 2> /dev/null

img-clean: img-rm-dang img-rm ## clean dangling and jupyter images

img-list: ## list jupyter images
	@echo "Listing $(OWNER) images ..."
	docker images "$(OWNER)/*"

img-rm:  ## remove jupyter images
	@echo "Removing $(OWNER) images ..."
	-docker rmi --force $(shell docker images --quiet "$(OWNER)/*") 2> /dev/null

img-rm-dang: ## remove dangling images (tagged None)
	@echo "Removing dangling images ..."
	-docker rmi --force $(shell docker images -f "dangling=true" -q) 2> /dev/null

run: DARGS?=
run: ## run a bash in interactive mode in a stack
	docker run -it --rm -v "$(PWD)":/home/gradle/project -w /home/gradle/project $(DARGS) $(OWNER)/$(IMAGE) $(SHELL)

gradle/%: GARGS?=
gradle/%: ## run a bash in interactive mode as root in a stack
	#docker run --rm -u gradle  gradle:latest gradle <gradle-task>
	docker run -it --rm -v "$(PWD)":/home/gradle/project -w /home/gradle/project $(DARGS) $(OWNER)/$(IMAGE) gradle $(notdir $@)
