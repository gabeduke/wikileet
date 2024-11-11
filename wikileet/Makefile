.PHONY: run
run:
	flutter run -d chrome --web-hostname localhost --web-port 5000

.PHONY: init
init:
	firebase init hosting

.PHONY: build
build: 
	flutter build web

.PHONY: publish
publish: build
	firebase deploy
