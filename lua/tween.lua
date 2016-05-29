
local AppData = {};
AppData.current = LXZPoint:new();

local function OnTweenRender(window, msg, sender)

end

local function OnTweenClickDown(window, msg, sender)
	--LXZMessageBox("OnTest:"..sender:GetName());	
	local root = HelperGetRoot();
	AppData.current.x = msg:int();
	AppData.current.y = msg:int();	
	
	local rect = LXZRect:new_local();
	sender:GetRect(rect);	
	rect:Deflate(10,10,10,10);
	if rect:IsIncludePoint(AppData.current) then
		HelperSetResizeWindow(sender);
	end		
	
end

local function OnTweenClickUp(window, msg, sender)
	--LXZMessageBox("OnTest:"..sender:GetName());
	AppData.isclickdown=false;
	if sender:GetChild("menus") then
		sender:GetChild("menus"):Show();
	end

end

local function OnTweenMouseMove(window, msg, sender)
	--LXZMessageBox("OnTest:"..sender:GetName());
end

local event_callback={};
--event_callback ["OnTweenRender"] = OnTweenRender;
event_callback ["OnTweenClickDown"] = OnTweenClickDown;
event_callback ["OnTweenClickUp"] = OnTweenClickUp;
event_callback ["OnTweenMouseMove"] = OnTweenMouseMove;

function tween_main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end
