-- By default, package.path includes "./?.lua" but not "./?/init.lua".
-- This file is a workaround for loading and testing the module
-- from the current directory.
return require "gumbo.init"
