include mk/compat.mk
include mk/lua.mk
include mk/lib.mk
include mk/build.mk
include mk/check.mk
include mk/dist.mk
include mk/doc.mk
-include mk/dev.mk

DOM_IFACES = \
    Element Text Comment Document DocumentFragment DocumentType \
    Attribute AttributeList DOMTokenList ElementList NodeList \
    Node ChildNode ParentNode

DOM_MODULES = $(addprefix gumbo/dom/, $(addsuffix .lua, $(DOM_IFACES) util))
SLZ_MODULES = $(addprefix gumbo/serialize/, Indent.lua html.lua)
TOP_MODULES = $(addprefix gumbo/, Buffer.lua Set.lua constants.lua sanitize.lua)
INSTALL_ALL = $(addprefix install-, $(BUILD_VERS))

all: build-any

install-all: $(INSTALL_ALL)

$(INSTALL_ALL): LUA_LMOD_DIR = $(LUA$*_LMODDIR)
$(INSTALL_ALL): LUA_CMOD_DIR = $(LUA$*_CMODDIR)
$(INSTALL_ALL): install-lua%: build-lua%
	@test "$(LUA_LMOD_DIR)" -a "$(LUA_CMOD_DIR)" || { echo error; exit 1; }
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) $(TOP_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(SLZ_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(INSTALL) $(DOM_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALLX) build/lua$*/gumbo/parse.so '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(INSTALL) gumbo.lua '$(DESTDIR)$(LUA_LMOD_DIR)/'

clean-obj:
	$(RM) $(BUILD_ALL) $(OBJ_ALL)

clean: clean-docs
	$(RM) -r build/
	$(RM) $(CLEANFILES)


.DEFAULT_GOAL = all
.PHONY: all install-all $(INSTALL_ALL) clean clean-obj
.DELETE_ON_ERROR:
