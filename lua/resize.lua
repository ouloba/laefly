
local STATE_RESIZE_LEFT=0;
local STATE_RESIZE_RIGHT=1;
local STATE_RESIZE_TOP=2;
local STATE_RESIZE_BOTTOM=3;
local STATE_RESIZE_DRAG=4;

local AppData = {};
AppData.state = 0;
AppData.isclickdown=false;
AppData.self_rect = LXZRect:new_local();
AppData.wnd_rect = LXZRect:new_local();
AppData.org = LXZPoint:new_local();

local function OnLoad(window, msg, sender)
end

local function OnSysLClickDown(window, msg, sender)
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();

	local root = HelperGetRoot();
	local wnd = CLXZWindow:FromHandle(sender:GetAddData());
	if wnd == nil then
		LXZAPI_OutputDebugStr("0 AddString:".. sender:GetAddString());
		return;
	end
	
	LXZAPI_OutputDebugStr("1 AddString:".. sender:GetAddString());
	
	wnd:GetRect(AppData.wnd_rect);
	sender:GetRect(AppData.self_rect);
	
	if AppData.self_rect:IsIncludePoint(pt)==false then
		LXZAPI_OutputDebugStr("2 AddString:".. sender:GetAddString());
		HelperSetCursorState(HelperGetCursorState("normal"));
		HelperSetResizeWindow(nil);
		return;
	end
	
	AppData.isclickdown=true;	
	AppData.org.x = pt.x;
	AppData.org.y = pt.y;
	
	local rect = AppData.self_rect;
	if math.abs(rect.left-pt.x) < 10 then
		AppData.state = STATE_RESIZE_LEFT;	
		HelperSetCursorState(HelperGetCursorState("horization"));
	elseif math.abs(rect.right-pt.x) < 10 then
		AppData.state = STATE_RESIZE_RIGHT;
		HelperSetCursorState(HelperGetCursorState("horization"));
	elseif math.abs(rect.top-pt.y) < 10 then
		AppData.state = STATE_RESIZE_TOP;
		HelperSetCursorState(HelperGetCursorState("vertical"));
	elseif math.abs(rect.bottom-pt.y) < 10 then
		AppData.state = STATE_RESIZE_BOTTOM;
		HelperSetCursorState(HelperGetCursorState("vertical"));
	elseif rect:IsIncludePoint(pt) then
		AppData.state = STATE_RESIZE_DRAG;
		HelperSetCursorState(HelperGetCursorState("drag"));
	end
	
	LXZAPI_OutputDebugStr("3 AddString:".. sender:GetAddString().." ["..rect.left..","..rect.top..","..rect.right..","..rect.bottom.."] "..pt.x..","..pt.y);
	local corecfg = ICGuiGetLXZCoreCfg();
	
	--LXZMessageBox("AddString:".. sender:GetAddString());
	
end

local function OnSysMouseMove(window, msg, sender)
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();
		
	if AppData.isclickdown==false then
		sender:GetRect(AppData.self_rect);
		local rect = AppData.self_rect;
		local state = 0;
		if math.abs(rect.left-pt.x) < 10 then		
			state = HelperGetCursorState("horization");			
		elseif math.abs(rect.right-pt.x) < 10 then
			state = HelperGetCursorState("horization");
		elseif math.abs(rect.top-pt.y) < 10 then
			state = HelperGetCursorState("vertical");
		elseif math.abs(rect.bottom-pt.y) < 10 then
			state = HelperGetCursorState("vertical");
		elseif rect:IsIncludePoint(pt)==true then			
			state = HelperGetCursorState("drag");
			--HelperSetCursorState();
			--
		end
				
		HelperSetCursorState(state);
		LXZAPI_OutputDebugStr("OnSysMouseMove:".. state.." name:"..sender:GetName());
		return;
	end
	
	local root = HelperGetRoot();
	local wnd = CLXZWindow:FromHandle(sender:GetAddData());
	if wnd == nil then
		return;
	end
	
	--save
	wnd:GetRect(AppData.wnd_rect);
	sender:GetRect(AppData.self_rect);
	
	local menus = root:GetLXZWindow("menus");
	local rc = AppData.self_rect;
	local pt1 = rc:TopRight();
	pt1.x = pt1.x-menus:GetWidth()/2;
	pt1.y = pt1.y-menus:GetHeight()/2;
	menus:SetHotPos(pt1,true);
	
	local old_self=LXZPoint:new_local();
	local old_wnd=LXZPoint:new_local();
	sender:GetHotPos(old_self, true);
	wnd:GetHotPos(old_wnd, true);
			
	local offset_x = pt.x-AppData.org.x;
	local offset_y = pt.y-AppData.org.y;

	--set size
	if AppData.state==STATE_RESIZE_LEFT then
		if (wnd:GetWidth()+offset_x)<10 then
			return;
		end
	
		local pos_self = LXZPoint:new_local();
		local pos_wnd = LXZPoint:new_local();
		wnd:GetPos(pos_wnd);
		sender:GetPos(pos_self);
		
		pos_self.x=pos_self.x+offset_x;
		pos_wnd.x=pos_wnd.x+offset_x;
		wnd:SetPos(pos_wnd);
		sender:SetPos(pos_self);
		
		wnd:SetWidth(wnd:GetWidth()-offset_x);
		sender:SetWidth(sender:GetWidth()-offset_x);
	elseif AppData.state==STATE_RESIZE_RIGHT then
		if (wnd:GetWidth()+offset_x)<10 then
			return;
		end
		
		wnd:SetWidth(wnd:GetWidth()+offset_x);
		sender:SetWidth(sender:GetWidth()+offset_x);
	elseif AppData.state==STATE_RESIZE_TOP then
		if (wnd:GetHeight()+offset_y)<10 then
			return;
		end
	
		local pos_self = LXZPoint:new_local();
		local pos_wnd = LXZPoint:new_local();
		wnd:GetPos(pos_wnd);
		sender:GetPos(pos_self);
		
		pos_self.y=pos_self.y+offset_y;
		pos_wnd.y=pos_wnd.y+offset_y;
		wnd:SetPos(pos_wnd);
		sender:SetPos(pos_self);
		
		wnd:SetHeight(wnd:GetHeight()-offset_y);
		sender:SetHeight(sender:GetHeight()-offset_y);
	elseif AppData.state==STATE_RESIZE_BOTTOM then
		if (wnd:GetHeight()+offset_y)<10 then
			return;
		end
		
		wnd:SetHeight(wnd:GetHeight()+offset_y);	
		sender:SetHeight(sender:GetHeight()+offset_y);
	elseif AppData.state==STATE_RESIZE_DRAG then
		local pos_self = LXZPoint:new_local();
		local pos_wnd = LXZPoint:new_local();
		wnd:GetPos(pos_wnd);
		sender:GetPos(pos_self);
		
		pos_self.x=pos_self.x+offset_x;
		pos_self.y=pos_self.y+offset_y;
		
		pos_wnd.x=pos_wnd.x+offset_x;
		pos_wnd.y=pos_wnd.y+offset_y;
		wnd:SetPos(pos_wnd);
		sender:SetPos(pos_self);
	end
	
	--
	AppData.org.x = pt.x;
	AppData.org.y = pt.y;
end

local function OnSysLClickUp(window, msg, sender)
	local x = msg:int();
	local y = msg:int();
	AppData.isclickdown=false;
	if sender:HitTest(x,y)==nil then
		HelperSetResizeWindow(nil);
	end
end

AppData.color    = RGBA:new();
AppData.color.red     = 192;
AppData.color.green = 192;
AppData.color.blue    = 192;
AppData.color.alpha  = 100;

local function OnUserRender(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = CLXZWindow:FromHandle(sender:GetAddData());
	if wnd == nil then
		sender:Hide();		
		return;
	end
	--[[
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	AppData.color.red     = 100;
	dc:DrawRect(AppData.self_rect, AppData.color);
	
	AppData.color.red     = 50;
	dc:DrawRect(AppData.wnd_rect, AppData.color);--]]
	
end

function HelperSetResize(resize_name)
	AppData.resize_name = resize_name;
end

function HelperSetResizeWindow(wnd)	
	local root = HelperGetRoot();
	local menus=root:GetLXZWindow("menus");
	local window = root:GetLXZWindow(AppData.resize_name);
	if wnd==nil then
		window:SetAddData(0);
		window:Hide();		
		menus:Hide();
		LXZAPI_OutputDebugStr("HelperSetResizeWindow Hide,"..AppData.resize_name);
		return;
	end
	
	local rc = LXZRect:new_local();
	local pos = LXZPoint:new_local();	
	wnd:GetHotPos(pos, true);		
	window:SetWidth(wnd:GetWidth()+20);
	window:SetHeight(wnd:GetHeight()+20);
	window:SetAddData(wnd:GetWindowHandle());
	window:Show();
	window:SetHotPos(pos, true);
	window:GetRect(rc);
	local pt = rc:TopRight();
	pt.x = pt.x-menus:GetWidth()/2;
	pt.y = pt.y-menus:GetHeight()/2;
	HelperSetCursorState(HelperGetCursorState("drag"));	
	menus:Show();
	menus:SetHotPos(pt, true);
	LXZAPI_OutputDebugStr("AddString:"..wnd:GetWindowHandle().." window:"..wnd:GetLongName());
end

local function delete_tween()
	local root = HelperGetRoot();
	local window = root:GetLXZWindow(AppData.resize_name);
	local handle = window:GetAddData();
	--	LXZMessageBox("OnMenuItems:".. sender:GetName().." handle:"..handle);
		local wnd = CLXZWindow:FromHandle(handle);
		if wnd then
			local child = wnd:GetFirstChild();
			while child do
				if child:GetClassName()=='in' or child:GetClassName()=='out' then
					local handle=child:GetAddData();
					local node = CLXZWindow:FromHandle(handle);
					if node then
						node:SetAddData(0);
					end
				end
			
				child = child:GetNextSibling();
			end
		
			wnd:Delete();
		end
		window:SetAddData(0);
		root:GetLXZWindow("menus"):Hide();
end

local function OnMenuItems(window, msg, sender)
	
	local root = HelperGetRoot();
	local window = root:GetLXZWindow(AppData.resize_name);
	if sender:GetName()=="edit" then
		local wnd = root:GetLXZWindow("tween info");
		wnd:Show();
	elseif sender:GetName()=="delete" then
		delete_tween();
	end
end


local function OnKeyDown(window, msg, sender)
		local u4Key = msg:uint32();
		if u4Key==LXZKEY_DELETE then
			delete_tween();
		end
end

local event_callback = {}
event_callback ["OnLoad"] = OnLoad;
event_callback ["OnResizeLClickDown"] = OnSysLClickDown;
event_callback ["OnResizeMouseMove"] = OnSysMouseMove;
event_callback ["OnResizeLClickUp"] = OnSysLClickUp;
event_callback ["OnUserRender"] = OnUserRender;
event_callback ["OnMenuItems"] = OnMenuItems;
event_callback ["OnResizeKeyDown"] = OnKeyDown;

function resize_main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end
