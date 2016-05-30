
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
	AppData.isclickdown=true;
	
	local wnd = sender:HitTest0(pt.x,pt.y);
	if wnd == nil then
		AppData.drag_wnd=nil;
		return;
	end
	
	if AppData.drag_wnd== nil then
		if wnd:GetName()=="in" or wnd:GetName()=="out" then
			AppData.drag_wnd = wnd;
		else
			LXZAPI_OutputDebugStr("OnSysLClickDown 2222");
		end	
		LXZAPI_OutputDebugStr("OnSysLClickDown 111:"..wnd:GetName());
	else
		AppData.drag_wnd=nil;
		LXZAPI_OutputDebugStr("OnSysLClickDown nil");
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
		LXZAPI_OutputDebugStr("drag_wnd:"..AppData.drag_wnd:GetLongName())
		
		local handle = AppData.drag_wnd:GetAddData();
		local wnd = CLXZWindow:FromHandle(handle);
		if wnd and wnd:Distance(AppData.drag_wnd)>20 then
			wnd:SetAddData(0);
			AppData.drag_wnd:SetAddData(0);
		end
	end
	
end

local function get_link_other_node(wnd)
	local w = wnd:GetParent();
	local in_=w:GetChild("in");
	local out_=w:GetChild("out");
	if in_==wnd then
		return out_;
	end	
	return in_;	
end

local function is_may_link_self(wnd,window)
	local p1=wnd:GetParent();
	local other = get_link_other_node(window);
	local handle = other:GetAddData();
	local node = CLXZWindow:FromHandle(handle);
	if node == nil then
		return false;
	end
	
	if p1==node:GetParent() then
		return true;
	end
	
	return false;	
end

local function is_link_match(wnd,window)
	if wnd == nil or window==nil then
		return false;
	end

	if wnd:GetAddData()~=0 then
		return false;
	end
	
	if window:GetAddData()~=0 then
		return false;
	end
	
	if wnd:GetClassName()=="in"  and window:GetClassName()=="out" then
		if(is_may_link_self(wnd, window)) then
			return false;
		end		
		return  true;
	elseif wnd:GetClassName()=="out"  and window:GetClassName()=="in" then
		if(is_may_link_self(wnd, window)) then
			return false;
		end		
		return true;
	end
	
	return false;
end

local function OnSysLClickUp(window, msg, sender)
	local x = msg:int();
	local y = msg:int();
	AppData.isclickdown=false;
		
	local root = HelperGetRoot();
	local tween_layer = root:GetLXZWindow("canvas:tween layer");
	local wnd = tween_layer:HitTest0(AppData.current.x, AppData.current.y);
	if is_link_match(wnd, AppData.drag_wnd) then
		wnd:SetAddData(AppData.drag_wnd:GetWindowHandle());
		AppData.drag_wnd:SetAddData(wnd:GetWindowHandle());		
		sender:BookMsg("OnMove", "OnTweenMove", wnd:GetParent());
	end	
	AppData.drag_wnd=nil;
end

AppData.color    = RGBA:new();
AppData.color.red     = 192;
AppData.color.green = 192;
AppData.color.blue    = 192;
AppData.color.alpha  = 100;

local function DrawInOutBox(window)
	if AppData.drag_wnd == nil then
		return;
	end

	local dc = LXZAPI_GetDC();
	local rc = LXZRect:new_local();
	local wnd = window:GetFirstChild();
	while wnd do
		if wnd:GetClassName()~=AppData.drag_wnd:GetName() and wnd:GetAddData()==0 then
			wnd:GetRect(rc);
			dc:DrawRect(rc, AppData.color);
		end		
		wnd=wnd:GetNextSibling();
	end
end

local function DrawArrow(from, to)
	local vec = LXZVector2D:new_local(to.x-from.x, to.y-from.y);
	vec:normalize();	
end

local function OnUserRender(window, msg, sender)
	local root = HelperGetRoot();
	local tween_layer = root:GetLXZWindow("canvas:tween layer");
	
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	sender:GetRect(AppData.rect);	
	local rect = AppData.rect;
	
	local pt = LXZPoint:new_local();
	local pt1 = LXZPoint:new_local();
	
	local out_ = sender:GetChild("out");	
	local in_ = sender:GetChild("in");
				
	local handle_in = in_:GetAddData();
	local handle_out = out_:GetAddData();
		
	local rc = LXZRect:new_local();	
	local in_link = CLXZWindow:FromHandle(handle_in);
	local out_link = CLXZWindow:FromHandle(handle_out);
	if in_link and out_link then
		in_link:GetHotPos(pt1, true);
		out_link:GetHotPos(pt, true);
		dc:DrawLine(pt1, pt, AppData.color);
		--HelperShowRender(out_,"Picture", true);
	elseif in_link then
		out_:GetHotPos(pt1, true);
		in_link:GetHotPos(pt, true);
		dc:DrawLine(pt1, pt, AppData.color);
		out_:GetRect(rc);
		rc:Deflate(6,6,6,6);
		dc:FillRect(rc, AppData.color);
		out_:SetAddData(0);
		--HelperShowRender(out_,"Picture", false);
	elseif out_link then
		in_:GetHotPos(pt1, true);
		out_link:GetHotPos(pt, true);
		dc:DrawLine(pt1, pt, AppData.color);
		in_:GetRect(rc);
		rc:Deflate(6,6,6,6);
		dc:FillRect(rc, AppData.color);
		in_:SetAddData(0);
		--HelperShowRender(out_,"Picture", true);
	else
		in_:SetAddData(0);
		out_:SetAddData(0);
	
		in_:GetHotPos(pt1, true);
		out_:GetHotPos(pt, true);
		dc:DrawLine(pt1, pt, AppData.color);
		
		out_:GetRect(rc);
		rc:Deflate(6,6,6,6);
		dc:FillRect(rc, AppData.color);
		
		in_:GetRect(rc);
		rc:Deflate(6,6,6,6);
		dc:FillRect(rc, AppData.color);
	end
		
	local wnd = tween_layer:HitTest0(AppData.current.x, AppData.current.y);
	if wnd and wnd:GetParent():GetClassName()=="tween" then	
	
		wnd:GetRect(rc);
		rc:Deflate(5,5,5,5);
		
		--LXZAPI_OutputDebugStr ("HitTest0:".. wnd:GetName());				
		if  is_link_match(wnd,AppData.drag_wnd) then
			AppData.color.green=255;
			AppData.color.red     = 0;			
			dc:FillRect(rc, AppData.color);
		else
			AppData.color.green= 0;
			AppData.color.red     = 255;			
			dc:FillRect(rc, AppData.color);
		end
	end
	
	if AppData.isclickdown==true then
		local wnd = tween_layer:GetFirstChild();
		while wnd do
			DrawInOutBox(wnd);
			wnd = wnd:GetNextSibling();
		end		
	end
	
	AppData.color.blue = 255;
	AppData.color.green=255;
	AppData.color.red     =255;
	
end

local function OnNodeShouldMove(window, msg, sender)
	
	local pt = LXZPoint:new_local();
	local wnd = sender:GetFirstChild();
	while wnd do
		if wnd:GetClassName()=="in" or wnd:GetClassName()=="out" then
			local handle = wnd:GetAddData();
			local w= CLXZWindow:FromHandle(handle);
			if w then
				w:GetHotPos(pt, true);
				wnd:SetHotPos(pt,true);		
				LXZAPI_OutputDebugStr(w:GetLongName().." x:"..pt.x.." y:"..pt.y);
			end			
		end
	
		wnd=wnd:GetNextSibling();
	end
	
end

--module ("copas", package.seeall)

local event_callback = {}
event_callback ["OnLinkLClickDown"] = OnSysLClickDown;
event_callback ["OnLinkMouseMove"] = OnSysMouseMove;
event_callback ["OnLinkLClickUp"] = OnSysLClickUp;
event_callback ["OnUserRender"] = OnUserRender;
event_callback ["OnNodeShouldMove"] = OnNodeShouldMove;

function link_main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end

