
local STATE_LINK_EMPTY= 0;
local STATE_LINK_IN          = 1;
local STATE_LINK_OUT      = 2;
local STATE_LINK_ALL       = 3;
local STATE_LINKING_IN    = 4;
local STATE_LINKING_OUT= 5;

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
	
	if AppData.state==STATE_LINK_EMPTY then
		local pos = get_from(sender);
		local vec=LXZVector2D:new_local();
		vec.x=pos.x-pt.x;
		vec.y=pos.y-pt.y;
		if math.sqrt(vec.x*vec.x+vec.y*vec.y)<10 then
			AppData.state=STATE_LINKING_IN;
			AppData.current.x=pt.x;
			AppData.current.y=pt.y;
			--LXZMessageBox("OnSysLClickDown:SATE_LINKING_IN");
		end
	end
	
end

local function OnSysMouseMove(window, msg, sender)
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();

	AppData.current.x=pt.x;
	AppData.current.y=pt.y;
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
	local canvas = root:GetLXZWindow("canvas");
	
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	sender:GetRect(AppData.rect);	
	local rect = AppData.rect;
	
	local from = rect:TopLeft();
	local to     = rect:BottomLeft();
	from.x = from.x+rect:Width()/2;
	to.x = to.x+rect:Width()/2;
	
	if AppData.state==STATE_LINK_EMPTY then
		AppData.color.red     = 100;
		dc:DrawLine(from, to, AppData.color);
	elseif AppData.state==STATE_LINKING_IN then
		AppData.color.red     = 100;
		dc:DrawLine(from, to, AppData.color);
		
		AppData.color.red     = 150;
		dc:DrawLine(from, AppData.current, AppData.color);
		
		local wnd = canvas:HitTest(AppData.current.x, AppData.current.y);
		if wnd and wnd:GetClassName()=="tween" then
			local rc = LXZRect:new_local();
			rc.left = AppData.current.x-5;
			rc.right = AppData.current.x+5;
			rc.bottom = AppData.current.y+5;
			rc.top = AppData.current.y-5;			
			dc:DrawRect(rc, AppData.color);
		end
	elseif AppData.state==STATE_LINKING_OUT then
		AppData.color.red     = 100;
		dc:DrawLine(from, to, AppData.color);
		
		AppData.color.red     = 150;
		dc:DrawLine(to, AppData.current, AppData.color);
		
		local wnd = canvas:HitTest(AppData.current.x, AppData.current.y);
		if wnd and wnd:GetClassName()=="tween" then
			local rc = LXZRect:new_local();
			rc.left = AppData.current.x-5;
			rc.right = AppData.current.x+5;
			rc.bottom = AppData.current.y+5;
			rc.top = AppData.current.y-5;			
			dc:DrawRect(rc, AppData.color);
		end
	elseif AppData.state==STATE_LINK_IN then
		local in_ = sender:GetChild("in");
		
	end
	
end

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
