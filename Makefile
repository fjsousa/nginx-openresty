DOCKER_IMAGE=fjsousa/nginx-openresty
DOCKER_TAG?=$(shell git rev-parse HEAD)

.PHONY: all build docker-build docker-push info

all: docker-build docker-push info

docker-build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) -t $(DOCKER_IMAGE):latest .

docker-push:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	docker push $(DOCKER_IMAGE):latest 

info:
	@echo "Made $(DOCKER_IMAGE):$(DOCKER_TAG)"