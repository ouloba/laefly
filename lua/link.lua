
local AppData = {};
AppData.state = 0;
AppData.isclickdown=false;
AppData.rect = LXZRect:new();
AppData.current = LXZPoint:new();

local function get_from(wnd)
	wnd:GetRect(AppData.rect);	
	local rect = AppData.rect;	
	local from = rect:TopLeft();	
	from.x = from.x+rect:Width()/2;
	return from;	
end

local function get_to(wnd)
	wnd:GetRect(AppData.rect);	
	local rect = AppData.rect;	
	local to = rect:BottomLeft();	
	to.x = tox+rect:Width()/2;
	return to;	
end

local function OnSysLClickDown(window, msg, sender)
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();
	AppData.current.x=pt.x;
	AppData.current.y=pt.y;
	
	local wnd = sender:HitTest0(pt.x,pt.y);
	if wnd == nil then
		AppData.drag_wnd=nil;
		return;
	end
	
	if wnd:GetName()=="in" or wnd:GetName()=="out" then
		AppData.drag_wnd = wnd;
	end	

end

local function OnSysMouseMove(window, msg, sender)
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();

	AppData.current.x=pt.x;
	AppData.current.y=pt.y;
	
	if AppData.drag_wnd then
		AppData.drag_wnd:SetHotPos(pt, true);
	end
	
end

local function OnSysLClickUp(window, msg, sender)
	local x = msg:int();
	local y = msg:int();
	AppData.isclickdown=false;
end

AppData.color    = RGBA:new();
AppData.color.red     = 192;
AppData.color.green = 192;
AppData.color.blue    = 192;
AppData.color.alpha  = 100;

local function OnUserRender(window, msg, sender)
	local root = HelperGetRoot();
	local canvas = root:GetLXZWindow("canvas:tween layer");
	
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	sender:GetRect(AppData.rect);	
	local rect = AppData.rect;
	
	local pt = LXZPoint:new_local();
	local from = rect:TopLeft();
	local to     = rect:BottomLeft();
	from.x = from.x+rect:Width()/2;
	to.x = to.x+rect:Width()/2;
	
	AppData.color.red     = 100;
	dc:DrawLine(from, to, AppData.color);
	
	sender:GetChild("in"):GetHotPos(pt, true);
	dc:DrawLine(from, pt, AppData.color);
	
	sender:GetChild("out"):GetHotPos(pt, true);
	dc:DrawLine(to, pt, AppData.color);
	
	local wnd = canvas:HitTest0(AppData.current.x, AppData.current.y);
	if wnd then
		local rc = LXZRect:new_local();
		wnd:GetRect(rc);
		rc:Deflate(5,5,5,5);
		
		LXZAPI_OutputDebugStr ("HitTest0:".. wnd:GetName());
		
		if  wnd:GetClassName()=="in" then
			if AppData.drag_wnd:GetName()=="in" then
				AppData.color.green=0;
				AppData.color.red     = 255;
			else
				AppData.color.green=255;
				AppData.color.red     = 0;
			end
			dc:DrawRect(rc, AppData.color);
		elseif wnd:GetClassName()=="out" then		
			if AppData.drag_wnd:GetName()=="in" then
				AppData.color.green= 255;
				AppData.color.red     = 0;
			else
				AppData.color.green=0;
				AppData.color.red     =255;
			end
			dc:DrawRect(rc, AppData.color);
		end
	end
	
	AppData.color.green=255;
	AppData.color.red     =255;
	
end

--module ("copas", package.seeall)

local event_callback = {}
event_callback ["OnSysLClickDown"] = OnSysLClickDown;
event_callback ["OnSysMouseMove"] = OnSysMouseMove;
event_callback ["OnSysLClickUp"] = OnSysLClickUp;
event_callback ["OnUserRender"] = OnUserRender;

function link_main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end

