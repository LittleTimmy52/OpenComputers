local r, m, s = component.proxy(component.list("redstone")()), component.proxy(component.list("modem")()), component.proxy(component.list("sign")())
local p, d, t = 808, "door1", s.getValue()
local tp, td = t:match("([^\n]+)\n([^\n]+)")

if tp ~= nil and td ~= nil then
	p = tonumber(tp)
	d = td
end

m.open(p)

while true do
	local type, _, _, _, _, msg = computer.pullSignal()
	if type == "modem_message" then
		if msg == d .. " open" then
			r.setOutput(2, 15)
		elseif msg == d .. " close" then
			r.setOutput(2, 0)
		end
	end
end