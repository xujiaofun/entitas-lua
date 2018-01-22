
local class = require 'middleclass'
list = require 'list'
require 'event'

local Entity = class("Entity")

function Entity:initialize(  )
	self.on_component_added = event("on_component_added")

	self.on_component_removed = event("on_component_removed")

	self.on_component_replaced = event("on_component_replaced")

	self._components = {}

	self._creation_index = 0

	self._is_enabled = false
end

function Entity:activate( creation_index )
	self._creation_index = creation_index
	self._is_enabled = true
end

function Entity:add( comp_type, ... )
	print("comp_type", comp_type.name, tostring(self))
	if not self._is_enabled then
		error(string.format("Cannot add component %s: %s is not enabled.", comp_type.name, tostring(self)))
	end

	if self:has(comp_type) then
		error(string.format("Cannot add another component %s to %s.", comp_type.name, tostring(self)))
	end

	local new_comp = comp_type:new(...)
    self._components[comp_type] = new_comp
    self.on_component_added(self, new_comp)
end

function Entity:has( ... )
	local args = {...}
	if #args == 1 then
		return self._components[args[1]]
	end

	for _,comp_type in pairs(args) do
		if not self._components[comp_type] then
			return false
		end
	end
	return true
end

function Entity:hasAny( ... )
	local args = {...}
	for _,comp_type in pairs(args) do
		if self._components[comp_type] then
			return true
		end
	end
	return false
end

local Position = class("Position")

function Position:initialize( x, y )
	self.x = x
	self.y = y
	self:toString()
end

function Position:toString(  )
	print(string.format("%s - %s", self.x, self.y))
end

local e = Entity:new()
e:activate(0)
e:add(Position, 1, 3)


return Entity

