--------------------------------------------------------------------------------
--      Copyright (c) 2015 - 2016 , 蒙占志(topameng) topameng@gmail.com
--      All rights reserved.
--      Use, modification and distribution are subject to the "MIT License"
--------------------------------------------------------------------------------

local setmetatable = setmetatable
local xpcall = xpcall
local pcall = pcall
local assert = assert
local rawget = rawget
local error = error
local print = print
local ilist = ilist

local traceback = function (msg, title)
    if me.platform ~= 'win32' then 
        BuglyHelper.reportException(msg, title or "traceback\n" .. debug.traceback())
        return 
    end
    DeviceHelper.messageBox(tostring(msg) .. "\nerror:" .. debug.traceback(), title and tostring(title))
end

local _xpcall = {}
setmetatable(_xpcall, _xpcall)

_xpcall.__call = function(self, ...)	
	local flag 	= true	
	local msg = nil	

	if jit then
		if nil == self.obj then
			flag, msg = xpcall(self.func, traceback, ...)					
		else		
			flag, msg = xpcall(self.func, traceback, self.obj, ...)					
		end
	else
		local args = {...}
			
		if nil == self.obj then
			local func = function() self.func(unpack(args)) end
			flag, msg = xpcall(func, traceback)					
		else		
			local func = function() self.func(self.obj, unpack(args)) end
			flag, msg = xpcall(func, traceback)
		end
	end
		
	return flag, msg
end

_xpcall.__eq = function(lhs, rhs)
	return lhs.func == rhs.func and lhs.obj == rhs.obj
end

local function xfunctor(func, obj)
	local st = {func = func, obj = obj}	
	setmetatable(st, _xpcall)		
	return st
end

local _pcall = {}

_pcall.__call = function(self, ...)
	local flag 	= true	
	local msg = nil	

	if nil == self.obj then
		flag, msg = pcall(self.func, ...)					
	else		
		flag, msg = pcall(self.func, self.obj, ...)					
	end
		
	return flag, msg
end

_pcall.__eq = function(lhs, rhs)
	return lhs.func == rhs.func and lhs.obj == rhs.obj
end

local function functor(func, obj)
	local st = {func = func, obj = obj}		
	setmetatable(st, _pcall)		
	return st
end

local _event = 
{	
	name	 = "",
	lock	 = false,
	keepSafe = false,
}

_event.__index = function(t, k)	
	return rawget(_event, k)
end

function _event:Add(func, obj)
	assert(func)		
	
	if self.keepSafe then			
		func = xfunctor(func, obj)
	else
		func = functor(func, obj)
	end	

	local find = self.list:find(func)
	if find then return find end

	if self.lock then
		table.insert(self.addList, func)
		return func
	else
		self.list:push(func)
		return func
	end	
end

function _event:Remove(func, obj)
	for i, v in ilist(self.list) do							
		if v.func == func and v.obj == obj then
			-- if self.lock and self.current ~= i then
			-- 	table.insert(self.rmList, i)
			-- else
			-- 	self.list:remove(i)
			-- end
			self.list:remove(i)
			break
		end
	end	
	for i=#self.addList,1,-1 do
		if self.addList[i].func == func and self.addList[i].obj == obj then
			table.remove(self.addList, i)
		end
	end
end

function _event:Count()
	return self.list.length
end	

function _event:Clear()
	self.list:clear()
	self.rmList = {}
	self.addList = {}
	self.lock = false
	self.current = nil
end

function _event:Dump()
	local count = 0
	
	for _, v in ilist(self.list) do
		if v.obj then
			print("update function:", v.func, "object name:", v.obj.name)
		else
			print("update function: ", v.func)
		end
		
		count = count + 1
	end
	
	print("all function is:", count)
end

_event.__call = function(self, ...)		
	local _list = self.list	
	self.lock = true
	local ilist = ilist			
	local flag, msg = false, nil

	for i, f in ilist(_list) do	
		self.current = i						
		flag, msg = f(...)
		
		if not flag then
			if self.keepSafe then								
				_list:remove(i)
			end
			self.lock = false		
			error(msg)				
		end
	end	

	for _, i in ipairs(self.rmList) do							
		_list:remove(i)		
	end

	self.rmList = {}
	self.lock = false
	self.current = nil			

	for _, fun in ipairs(self.addList) do
		local find = self.list:find(fun)
		if not find then
			_list:push(fun)
		end
	end

	self.addList = {}
end

setmetatable(_event, _event)

function event(name, safe)
	safe = safe or false
	return setmetatable({name = name, keepSafe = safe, lock = false, rmList = {}, addList = {}, list = list:new()}, _event)	
end

local Time = Time
StartBeat	= event("StartBeat", true)
UpdateBeat 		= event("Update", true)
CoUpdateBeat	= event("CoUpdate")				--只在协同使用

local UpdateBeat = UpdateBeat
local CoUpdateBeat = CoUpdateBeat

--逻辑update
function UpdateGame(deltaTime)
	Time:SetDeltaTime(deltaTime)
	StartBeat()
	UpdateBeat(deltaTime)
	CoUpdateBeat()
	Time.frameCount = Time.frameCount + 1
end

function PrintEvents()
	UpdateBeat:Dump()
end