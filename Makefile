NAME := docker-centos-tomcat
VERSION := 0.1
REGISTRY := ukhomeofficedigital
DATE := $(shell date)
GITMESSAGE = $(git log -1 --pretty=%B)

.PHONY: all help build run shell test tag_latest release

all: clean build run

help:
	@echo ""
	@echo "Usage for tomcat"
	@echo ""
	@echo "Build the container:"
	@echo "  make build"
	@echo ""
	@echo "Run the container with defaults:"
	@echo "  make run"
	@echo ""
	@echo "Start the container in interactive mode:"
	@echo "  make shell"
	@echo ""
	@echo "Tag the container:"
	@echo "  make tag_latest"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean"
	@echo ""
	@echo "Push container to repository:"
	@echo "  make release"

build:
	docker build -t $(NAME):$(VERSION) --rm=true .

run:
	docker run -d -v $(PWD)/ssl:/opt/tomcat/ssl -p 8080:8080 -p 8443:8443 --name ${NAME} $(NAME):$(VERSION)

shell:
	docker run -it -v $(PWD)/ssl:/opt/tomcat/ssl -p 8080:8080 -p 8443:8443 --entrypoint="/bin/bash" $(NAME):$(VERSION)

tag_latest:
	@echo
	@echo "Preparing release tag."
	@./utils/preparerelease.sh $(NAME) $(VERSION)
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(REGISTRY)/$(NAME):$(VERSION)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
