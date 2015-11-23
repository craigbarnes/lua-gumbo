HASFEATURE = $(findstring $(1), $(.FEATURES))
REQERROR   = Required feature "$(strip $(1))" not supported by $(MAKE)
REQUIRE    = $(and $(or $(HASFEATURE), $(error $(REQERROR))),)

$(call REQUIRE, else-if)
$(call REQUIRE, order-only)
$(call REQUIRE, target-specific)
$(call REQUIRE, shortest-stem)
