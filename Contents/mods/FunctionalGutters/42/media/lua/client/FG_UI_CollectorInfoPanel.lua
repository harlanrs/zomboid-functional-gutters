-- require "ISUI/ISPanel"
require "Fluids/ISFluidContainerPanel"

local enums = require("FG_Enums")
local utils = require("FG_Utils")
local isoUtils = require("FG_Utils_Iso")
local serviceUtils = require("FG_Utils_Service")

FG_UI_CollectorInfoPanel = ISFluidContainerPanel:derive("FG_UI_GutterInfoPanel");
