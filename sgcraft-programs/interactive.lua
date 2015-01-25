--
--   Interactive stargate control program
--   Shows stargate state and allows dialling
--   addresses selected from a list
--

dofile("config.lua")
dofile("compat.lua")
dofile("addresses.lua")

function round(num, idp)
local mult = 10^(idp or 0)
return math.floor(num * mult + 0.5) / mult
end

function pad(s, n)
  return s .. string.rep(" ", n - string.len(s))
end

function showMenu()
  setCursor(1, 1)
  for i, na in pairs(addresses) do
    print(string.format("%d %s", i, na[1]))
  end
  print("")
  print("D Disconnect")
  print("O Open Iris")
  print("C Close Iris")
  print("Q Quit")
  print("")
  write("Option? ")
end

function getIrisState()
  ok, result = pcall(sg.irisState)
  return result
end

function showState()
  locAddr = sg.localAddress()
  remAddr = sg.remoteAddress()
  state, chevrons, direction = sg.stargateState()
  energy = sg.energyAvailable() * 80
  iris = sg.irisState()
  showAt(30, 1, "Local:     " .. locAddr)
  showAt(30, 2, "Remote:    " .. remAddr)
  showAt(30, 3, "State:     " .. state)
  showAt(30, 4, "Energy:    " .. round(energy, 0) .. " RF")
  showAt(30, 5, "Iris:      " .. iris)
  showAt(30, 6, "Engaged:   " .. chevrons)
  showAt(30, 7, "Direction: " .. direction)
end

function showAt(x, y, s)
  setCursor(x, y)
  write(pad(s, 50))
--  write(string.rep(" ", 20))
--  setCursor(x, y)
--  write(s)
end

function showMessage(mess)
  showAt(1, screen_height, mess)
--  setCursor(1, screen_height)
--  term.clearLine()
--  if mess then
--    write(mess)
--  end
end

function showError(mess)
  i = string.find(mess, ": ")
  if i then
    mess = "Error: " .. string.sub(mess, i + 2)
  end
  showMessage(mess)
end

handlers = {}

function dial(name, addr)
  showMessage(string.format("Dialling %s (%s)", name, addr))
  sg.dial(addr)
end

handlers[key_event_name] = function(e)
  c = key_event_char(e)
  if c == "d" then
    sg.disconnect()
  elseif c == "o" then
    sg.openIris()
  elseif c == "c" then
    sg.closeIris()
  elseif c == "q" then
    running = false
  elseif c >= "1" and c <= "9" then
    na = addresses[tonumber(c)]
    if na then
      dial(na[1], na[2])
    end
  end
end

function handlers.sgChevronEngaged(e)
  chevron = e[3]
  symbol = e[4]
  showMessage(string.format("Chevron %s engaged! (%s)", chevron, symbol))
end

function eventLoop()
  while running do
    showState()
    e = {pull_event()}
    name = e[1]
    f = handlers[name]
    if f then
      showMessage("")
      ok, result = pcall(f, e)
      if not ok then
        showError(result)
      end
    end
  end
end

function main()
  term.clear()
  showMenu()
  eventLoop()
  term.clear()
  setCursor(1, 1)
end

running = true
main()
