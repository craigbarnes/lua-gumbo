HASFEATURE = $(filter $(1), $(.FEATURES))
REQERROR   = Required feature "$(strip $(1))" not supported by $(MAKE)
REQUIRE    = $(and $(or $(HASFEATURE), $(error $(REQERROR))),)

$(call REQUIRE, else-if)
$(call REQUIRE, order-only)
$(call REQUIRE, target-specific)

ifeq "$(MAKE_VERSION)" "3.81"
  $(warning Disabling build optimization to work around a bug in GNU Make 3.81)
else
  make-lazy = $(eval $1 = $$(eval $1 := $(value $(1)))$$($1))
endif
