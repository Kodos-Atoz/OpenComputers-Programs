-- Version 0.52

-- Changelog:
-- Added TODO List
-- Mostly fixed indentation because OCD
-- Updated Pastebin with current code
-- Actually fixed indentation
-- Made lamp colours gradients
-- Added Light Board support
-- Made colorful lamps optional

-- ==================================

-- TODO
-- Add a way to have a second lamp track net gain/loss of power
-- Refactor (Is this even the right word) term.write to use
-- gpu.set instead, as well as setting it up so that only the
-- values that change every update will be redrawn, instead of
-- the entire GUI
-- Make things prettier on the front end

-- Code Start


local component = require("component")
local term = require("term")

local gpu = component.gpu            -- Note that this program requires a T3 Screen.

local lamp =  component.isAvailable("colorful_lamp") and component.colorful_lamp or nil

local blue = 0x1F

local bit32 = bit32 or load([[return {
    band = function(a, b) return a & b end,
    bor = function(a, b) return a | b end,
    bxor = function(a, b) return a ~ b end,
    bnot = function(a) return ~a end,
    rshift = function(a, n) return a >> n end,
    lshift = function(a, n) return a << n end,
}]])()  -- Thanks, Magik6k for the workaround code that I shamelessly sto- I mean borrowed!

gpu.setResolution(40,1)

local function checkBatt()
  local curr = 0
  for addr in component.list("capacitor_bank") do
    battcheck = component.proxy(addr).getEnergyStored()
    curr = curr + battcheck
  end
  return curr
end

local function getMaxBatt()
  local maxStorage = 0
  for addr in component.list("capacitor_bank") do
    maxcheck = component.proxy(addr).getMaxEnergyStored()
    maxStorage = maxStorage + maxcheck
  end
  return maxStorage
end

local function updateMon(curr, maxStorage)
  term.clear()
  local text = curr .. "/" .. maxStorage .. " RF Stored"
  term.setCursor(math.ceil((40 - #text) / 2), 1)
  io.stdout:write(text..".")
  return
end

local function updateLamp(curr, maxStorage)
  if not lamp then return end
  if curr == 0 and maxStorage == 0 then
    lamp.setLampColor(blue)
    return
  else
    local perc = curr / maxStorage
    local red = math.max(math.min(math.ceil(0x1C * ((1 - perc)*2)), 0x1C), 0)
    local green = math.max(math.min(math.ceil(0x1F * (perc * 2)), 0x1F), 0)
    lamp.setLampColor(bit32.bor(bit32.lshift(red, 10), bit32.lshift(green, 5)))
  end
end

local light = component.isAvailable("light_board") and component.light_board or nil
local prevCount = 0

local function updateLight()
  if not light then return prevCount end
  local count = light.light_count
  if count == prevCount then return count end
  prevCount = count
  for i = 1, count do
    local perc = i / count
    local red = math.max(math.min(math.ceil(0xE0 * ((1 - perc)*2)), 0xE0), 0)
    local green = math.max(math.min(math.ceil(0xFF * (perc * 2)), 0xFF), 0)
    light.setColor(i, bit32.bor(bit32.lshift(red, 16), bit32.lshift(green, 8)))
  end
  return count
end

local function updateDisplay(curr, maxStorage)
  if not light then return end
  local count = updateLight()
  local perc = curr / maxStorage
  for i = 1, count do
    light.setActive(i, i <= math.ceil(perc * count))
  end
end

while true do
  local maxStorage = getMaxBatt()
  local curr = checkBatt()
  updateMon(curr, maxStorage)
  updateLamp(curr, maxStorage)
  updateDisplay(curr, maxStorage)
  os.sleep(1)
end

-- Code End
