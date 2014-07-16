.PHONY: test test-integration compile

test: compile
	istanbul cover -- _mocha test -R spec ./spec

test-integration: compile
	rm integration/data/src/otherFn.js
	cd integration && mocha -R spec ./run

compile:
	coffee -c ./