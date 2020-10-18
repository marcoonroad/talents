all: test

install:
	luarocks make

install-local:
	luarocks --local make

uninstall:
	luarocks remove talents

uninstall-local:
	luarocks --local remove talents

check:
	luarocks lint `find . -name '*.rockspec' -print`
	luacheck --std max+busted src spec

test-unit: check
	busted --run=Unit

test-coverage: test-unit
	busted --run=Coverage
	luacov-coveralls -i src --dryrun

test: test-coverage

clean:
	rm -fv luacov.*.out
	rm -fv *.src.rock

.PHONY: clean

# END
