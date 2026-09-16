build:
	@swift build

format:
	@swift format format -r -i Sources Tests Package.swift

lint:
	@swift format lint --strict -r Sources Tests Package.swift

test:
	@swift test --parallel --disable-xctest

live:
	@STARK_SKYLIGHT_LIVE=1 swift test --disable-xctest --filter LiveTests

clean:
	@swift package clean

.DEFAULT_GOAL := build
.PHONY: build format lint test live clean
