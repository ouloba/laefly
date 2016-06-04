
local AppData = {};
AppData.current = LXZPoint:new();


AppData.color    = RGBA:new();
AppData.color.red     = 192;
AppData.color.green = 192;
AppData.color.blue    = 192;
AppData.color.alpha  = 100;

local function OnTweenRender(window, msg, sender)
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	local root = HelperGetRoot();
	if root:GetLXZWindow("resize"):IsVisible()==true then
		return;
	end
	
	local corecfg = ICGuiGetLXZCoreCfg();			
	if corecfg.IsClickDown==false then
		local wnd = sender:HitTest0(AppData.current.x, AppData.current.y);
		if wnd and (wnd:GetClassName()=="in" or wnd:GetClassName()=="out")  then
			local rc = LXZRect:new_local();
			wnd:GetRect(rc);
			dc:DrawRect(rc, AppData.color);
		end		
	end
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
	AppData.current.x = msg:int();
	AppData.current.y = msg:int();	
end

local function OnTweenMouseMove(window, msg, sender)
		local x=msg:int();
		local y=msg:int();
		AppData.current.x=x;
		AppData.current.y=y;
end

local function OnSysDBClick(window, msg, sender)
		local x=msg:int();
		local y=msg:int();
		AppData.current.x=x;
		AppData.current.y=y;
		local root = HelperGetRoot();
		local wnd = root:GetLXZWindow("wait timer input");
		if sender:GetName()=="wait timer" then
			local pt = LXZPoint:new_local();
			sender:GetHotPos(pt, true);
			local w = sender:GetWidth()+10;
			local h = sender:GetHeight()+10;
			wnd:SetWidth(w);
			wnd:SetHeight(h);
			wnd:Show();
			wnd:SetHotPos(pt, true);
			wnd:SetAddData(sender:GetWindowHandle());
		end
		
end

local function get_match_name(name)
	if name=="in" then
		return "out";	
	end
	return "in";
end


local function OnDrag(window, msg, sender)
	local x = msg:int();
	local y = msg:int();

	local root = HelperGetRoot();
	local layer = root:GetLXZWindow("canvas:link layer");
	local canvas = root:GetLXZWindow("canvas");
		
	if root:GetLXZWindow("resize"):IsVisible()==true then
		return;
	end
	
	local wnd = sender:HitTest0(x, y);
	if wnd and wnd:GetAddData()==0 then		
		local pt = LXZPoint:new_local();
		wnd:GetHotPos(pt,true);
		local link= root:GetLXZWindow("system:link"):Clone();
		layer:AddChild(link);
		link:SetHotPos(pt, true);				
		local match = link:GetChild(get_match_name(wnd:GetClassName()));
		match:SetAddData(wnd:GetWindowHandle());
		wnd:SetAddData(match:GetWindowHandle());
		link:GetChild("in"):SetHotPos(pt, true);
		link:GetChild("out"):SetHotPos(pt, true);
		link:LayerTop(link:GetChild(wnd:GetClassName()));
		canvas:ProcMessage("OnSysLClickDown", msg, canvas);
	end
end


local event_callback={};
--event_callback ["OnTweenRender"] = OnTweenRender;
event_callback ["OnTweenClickDown"] = OnTweenClickDown;
event_callback ["OnTweenClickUp"] = OnTweenClickUp;
event_callback ["OnTweenMouseMove"] = OnTweenMouseMove;
event_callback ["OnDrag"] = OnDrag;
event_callback ["OnSysDBClick"] = OnSysDBClick;
event_callback ["OnUserRender"] = OnTweenRender;




function tween_main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end
