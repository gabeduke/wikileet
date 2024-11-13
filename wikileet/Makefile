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
publish: clean build
	firebase deploy

.PHONY: clean
clean:
	flutter clean

.PHONY: test
test:
	flutter test
