include mk/compat.mk
include mk/lua.mk
include mk/lib.mk
include mk/build.mk
include mk/check.mk
include mk/dist.mk
include mk/doc.mk
-include mk/dev.mk

INSTALL = install
INSTALL_LMOD = $(INSTALL) -p -m644
INSTALL_CMOD = $(INSTALL) -p -m755
INSTALL_DIR = $(INSTALL) -d -m755

DOM_IFACES = \
    Element Text Comment Document DocumentFragment DocumentType \
    Attribute AttributeList DOMTokenList ElementList NodeList \
    Node ChildNode ParentNode

DOM_MODULES = $(addprefix gumbo/dom/, $(addsuffix .lua, $(DOM_IFACES) util))
SLZ_MODULES = $(addprefix gumbo/serialize/, Indent.lua html.lua)
TOP_MODULES = $(addprefix gumbo/, Buffer.lua Set.lua constants.lua sanitize.lua)
INSTALL_ALL = $(addprefix install-, $(BUILD_VERS))
INSTALL_ANY = $(addprefix install-, $(LUAS_FOUND))

all: build-any

install: $(INSTALL_ANY)
install-all: $(INSTALL_ALL)

$(INSTALL_ALL): LMOD_DIR = $(DESTDIR)$(LUA$*_LMODDIR)
$(INSTALL_ALL): CMOD_DIR = $(DESTDIR)$(LUA$*_CMODDIR)
$(INSTALL_ALL): install-lua%: build-lua%
	@test "$(LMOD_DIR)" -a "$(CMOD_DIR)" || { echo error; exit 1; }
	$(INSTALL_DIR) '$(CMOD_DIR)/gumbo/'
	$(INSTALL_DIR) '$(LMOD_DIR)/gumbo/serialize/'
	$(INSTALL_DIR) '$(LMOD_DIR)/gumbo/dom/'
	$(INSTALL_LMOD) $(TOP_MODULES) '$(LMOD_DIR)/gumbo/'
	$(INSTALL_LMOD) $(SLZ_MODULES) '$(LMOD_DIR)/gumbo/serialize/'
	$(INSTALL_LMOD) $(DOM_MODULES) '$(LMOD_DIR)/gumbo/dom/'
	$(INSTALL_CMOD) build/lua$*/gumbo/parse.so '$(CMOD_DIR)/gumbo/'
	$(INSTALL_LMOD) gumbo.lua '$(LMOD_DIR)/'

clean-obj:
	$(RM) -r build/

clean: clean-obj clean-docs
	$(RM) $(CLEANFILES)


.DEFAULT_GOAL = all
.PHONY: all install install-all $(INSTALL_ALL) clean clean-obj
.DELETE_ON_ERROR:
