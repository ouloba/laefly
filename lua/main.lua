LXZDoFile("LXZHelper.lua");
LXZDoFile("serial.lua");
LXZDoFile("resize.lua");

OFN_READONLY = 0x00000001
OFN_OVERWRITEPROMPT  =  0x00000002
OFN_HIDEREADONLY  = 0x00000004
OFN_NOCHANGEDIR =  0x00000008
OFN_SHOWHELP = 0x00000010
OFN_ENABLEHOOK  =  0x00000020
OFN_ENABLETEMPLATE  =  0x00000040
OFN_ENABLETEMPLATEHANDLE = 0x00000080
OFN_NOVALIDATE =  0x00000100
OFN_ALLOWMULTISELECT =  0x00000200
OFN_EXTENSIONDIFFERENT =   0x00000400
OFN_PATHMUSTEXIST =  0x00000800
OFN_FILEMUSTEXIST  =   0x00001000
OFN_CREATEPROMPT  =    0x00002000
OFN_SHAREAWARE =    0x00004000
OFN_NOREADONLYRETURN =   0x00008000
OFN_NOTESTFILECREATE   =  0x00010000
OFN_NONETWORKBUTTON  =     0x00020000
OFN_NOLONGNAMES =    0x00040000  --  // force no long names for 4.x modules
OFN_EXPLORER   =     0x00080000    -- // new look commdlg
OFN_NODEREFERENCELINKS  =   0x00100000
OFN_LONGNAMES     =    0x00200000   --  // force long names for 3.x modules

local AppData = {};
AppData.current = LXZPoint:new();
AppData.org       = LXZPoint:new();
AppData.from = LXZPoint:new();
AppData.to      = LXZPoint:new();
AppData.color    = RGBA:new();
AppData.color.red     = 192;
AppData.color.green = 192;
AppData.color.blue    = 192;
AppData.color.alpha  = 100;
AppData.isclickdown=false;
AppData.wnd = nil;

local callbackthread= {};
LXZAPI_HookSystemNotify("xxxOnSystemNotify");
function xxxOnSystemNotify(token, param,thread)
	if callbackthread[token]~= nil then
		coroutine.resume(callbackthread[token],param);
	end
end
	
local function OnLoad(window, msg, sender)
	--LXZMessageBox("OnTest:"..sender:GetName());
	local root = HelperGetRoot();
	--LXZMessageBox("OnLoad");
	--local test = root:GetLXZWindow("canvas:tween layer");
	local winmgr = CLXZWindowMgr:Instance();
	winmgr:SetCursor(root:GetLXZWindow("system:cursor"));
	HelperSetResize("resize");
end

local function OnUpdate(window, msg, sender)
	--LXZMessageBox("OnTest:"..sender:GetName());
	UpdateWindow();
end

local function GetParentByClass(wnd,cls)
	local parent = wnd;
	while parent do
		if parent:GetClassName()==cls then
			return parent;
		end	
		parent=parent:GetParent();
	end
end

local function  transfer_msg(x, y, cmd)	
	local root = HelperGetRoot();
	local canvas = root:GetLXZWindow("canvas");
	local wnd = root:HitTest(x,y,true);
	if canvas:IsChild(wnd)==false and canvas~=wnd then		
		if wnd then
			LXZAPI_OutputDebugStr("transfer_msg sss:"..cmd.." wnd:"..wnd:GetLongName());	
		end
		return;
	end
	
	local msg = CLXZMessage:new_local();
	msg:int(x);
	msg:int(y);	
	
	local move_wnd=CLXZWindow:FromHandle(MOVE_HANDLE);
	if cmd=="OnSysMouseMove" and move_wnd then
		 return move_wnd:ProcMessage(cmd, msg, move_wnd);
	elseif cmd=="OnSysLClickDown" and move_wnd then
		move_wnd:ProcMessage(cmd, msg, move_wnd);
	end
	
	local tween_layer = root:GetLXZWindow("canvas:link layer");
	local hit = tween_layer:HitTest0(x, y,false);
	if hit then	
		hit=GetParentByClass(hit,"link");
		LXZAPI_OutputDebugStr("transfer_msg:"..cmd.." hit:"..hit:GetLongName());				
		 hit:ProcMessage(cmd, msg, hit);
		 if cmd=="OnSysLClickDown" then
			MOVE_HANDLE=hit:GetWindowHandle();
		end
		return;
	end
	
	local tween_layer = root:GetLXZWindow("canvas:tween layer");
	local hit = tween_layer:HitTest0(x, y,false);
	if hit then		
		LXZAPI_OutputDebugStr("transfer_msg:"..cmd.." hit:"..hit:GetLongName());
		hit=GetParentByClass(hit,"tween");
		hit:ProcMessage(cmd, msg, hit);
		if cmd=="OnSysLClickDown" then
			MOVE_HANDLE=hit:GetWindowHandle();
		end
	end
	
	LXZAPI_OutputDebugStr("transfer_msg:"..cmd.." x:"..x.." y:"..y);
end

local function OnCanvasMouseMove(window, msg, sender)
	local pt = LXZPoint:new_local();
	local x = msg:int();
	local y = msg:int();
	transfer_msg(x,y, "OnSysMouseMove");
end

local function OnCanvasClickUp(window, msg, sender)
	local pt = LXZPoint:new_local();
	local x = msg:int();
	local y = msg:int();
	transfer_msg(x,y, "OnSysLClickUp");
end

local function OnCanvasDrag(window, msg, sender)
	local pt = LXZPoint:new_local();
	local x = msg:int();
	local y = msg:int();
	transfer_msg(x,y, "OnDrag");
end

local function OnCanvasDBClick(window, msg, sender)
	local pt = LXZPoint:new_local();
	local x = msg:int();
	local y = msg:int();
	transfer_msg(x,y, "OnSysDBClick");
end

local function OnCanvasKeyDown(window, msg, sender)	
	local move_wnd=CLXZWindow:FromHandle(MOVE_HANDLE);
	if move_wnd then
		 return move_wnd:ProcMessage("OnSysKeyDown", msg, move_wnd);
	end	
end

local function OnCanvasClickDown(window, msg, sender)
	local pt = LXZPoint:new_local();
	local x = msg:int();
	local y = msg:int();
	transfer_msg(x,y, "OnSysLClickDown");	
end

local function OnTreeItemRender(window, msg, sender)
	local childs = sender:GetChild("childs");
	local wnd = childs:GetFirstChild();
	if wnd == nil or childs:IsVisible()==false then
		return;
	end
	
	local rc = LXZRect:new_local();
	local pt = LXZPoint:new_local();	
	local pt1 = LXZPoint:new_local();

	childs:GetRect(rc);
	--childs:GetRect(rc);
	
	local dc = LXZAPI_GetDC();
	dc:SetBlendMode(BM_BLEND);
	
	local icon = sender:GetChild("icon");
	icon:GetHotPos(pt, true);
		
	pt1.x=pt.x;
	pt1.y=pt.y+childs:GetHeight()/2;
	
	dc:DrawLine(pt,pt1,AppData.color);
	
	pt.y=pt1.y;
	pt.x=rc.left;
	dc:DrawLine(pt1,pt,AppData.color);
	
	local p1=rc:TopLeft();
	local p2=rc:BottomLeft();
	dc:DrawLine(p1,p2,AppData.color);
	
	while wnd do
		wnd:GetChild("icon"):GetHotPos(pt, true);
		pt1.y = pt.y;
		pt1.x = rc.left;
		dc:DrawLine(pt1,pt,AppData.color);
		wnd = wnd:GetNextSibling();
	end
	
	--dc:DrawRect(rc, AppData.color);
		
end


local function OnWillAddElement(window, msg, sender)
	local root = HelperGetRoot();
	local pt = LXZPoint:new_local();
	sender:GetHotPos(pt, true);


	local wnd = root:GetLXZWindow("system:cursor");
	HelperSetEmbededWindow(wnd, sender:GetLongName());	
	wnd:Show();
	wnd:SetHotPos(pt, true);
end

local function OnCursorMove(window, msg, sender)
	if sender:GetClassName()=="tween" then
		return;
	end

end

local function OnDropElement(window, msg, sender)
	local root = HelperGetRoot();	
	if sender:GetParent()~=root:GetLXZWindow("dictions:dic") then
		return;
	end
	
	local wnd = root:GetLXZWindow("system:cursor");
	HelperSetEmbededWindow(wnd, "");	
	
	local layer = nil;
	if sender:GetName()=="link" then
		layer = root:GetLXZWindow("canvas:link layer");			
	else
		layer = root:GetLXZWindow("canvas:tween layer");
		if layer:GetChild("start") ~= nil and sender:GetName()=="start" then
			return;
		end
		
		if layer:GetChild("end") ~= nil and sender:GetName()=="end" then
			return;
		end
	end
			
	local pt = LXZPoint:new_local();
	pt.x = msg:int();
	pt.y = msg:int();		
	local wnd = root:GetLXZWindow("system:"..sender:GetName());
	local tween = wnd:Clone();
	layer:AddChild(tween);
	tween:SetHotPos(pt, true);
	if tween:GetChild("menus") then
		tween:GetChild("menus"):Hide();
	end
	
	--LXZMessageBox("OnDropElement:".. sender:GetName());
end

--tween info:property:reverse:value
local function  OnPropertyMsg_reverse_select(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:property:reverse:value:select");
	if wnd:GetState()==0 then
		wnd:SetState(1);
	else
		wnd:SetState(0);
	end
end

local function OnPropertyMsg_repeat_arrow(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Show();
	wnd:GetLXZWindow("repeat_menus"):Show();
end

local function OnPropertyMsg_transition_arrow(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Show();
	wnd:GetLXZWindow("transition_menus"):Show();
end

local function OnPropertyMsg_equation_arrow(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Show();
	wnd:GetLXZWindow("equation_menus"):Show();
end

local function OnPropertyMsg_repeat_menus(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Hide();
	wnd:GetLXZWindow("repeat_menus"):Hide();
	
	if sender:GetName()=="once" then
		HelperSetWindowText(root:GetLXZWindow("tween info:property:repeat:value"),"1");
	elseif sender:GetName()=="unlimit" then
		HelperSetWindowText(root:GetLXZWindow("tween info:property:repeat:value"),"-1");
	elseif sender:GetName()=="user" then
		local wnd = root:GetLXZWindow("tween info:property:repeat:value");
		wnd:DelBit(STATUS_IsDisable);
		wnd:SetFocus(true);
	end	
	
end

local function OnPropertyMsg_close_tween_info(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info");
	wnd:Hide();
	root:GetLXZWindow("head:tween_info_btn"):SetState(0);
end


local function OnPropertyMsg_close_ui_tree(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("ui tree");
	wnd:Hide();
	root:GetLXZWindow("head:ui_tree_btn"):SetState(0);
end

function reset_tree_position(wnd,y)	
	local pt = LXZPoint:new_local();
	pt.x = 0;
	pt.y = y;			
	wnd:SetPos(pt);	
	
	local icon = wnd:GetChild("icon");	
	local childs = wnd:GetChild("childs");
	
	if childs:GetFirstChild()~=nil then
		if childs:IsVisible()==true then
			icon:SetState(1);
		else
			icon:SetState(0);
		end
	else
		childs:Hide();
		icon:SetState(2);
	end
	
	if childs:IsVisible()==false then
		return wnd;
	end
	
	y=0;
	local rc = LXZRect:new_local();
	local child = childs:GetFirstChild();
	while child do
		local ww=reset_tree_position(child, y);
		ww:GetVisualFrame(rc, true, false);
		y = y +rc:Height();
		child = child:GetNextSibling();
	end
	
	return wnd;
end

function add_tree_item(cls,parent,wnd,y)

	--LXZMessageBox("add_tree_item cls:"..cls:GetName().." tree:".. tree:GetName().." wnd:".. wnd:GetName())
	local w = cls:Clone();
	w:SetName(wnd:GetName());
		
	local name = w:GetChild("name");
	local icon = w:GetChild("icon");
	HelperSetWindowText(name, wnd:GetName());		
	parent:AddChild(w);	

	local childs = w:GetChild("childs");
	local child = wnd:GetFirstChild();
	while child~=nil do				
		local ww=add_tree_item(cls,childs,child);
		child=child:GetNextSibling();		
	end	
			
	return w;
end

local function OnPropertyMsg_open_ui_tree(window, msg, sender)	

	HelperCoroutine(function(thread)
	
	--	LXZMessageBox("cls:"..cls:GetName().." class:"..cls:GetClassName())
	
		local alloc = ILXZAlloc:new();
		local msg = CLXZMessage:new_local();
		msg:uint32(bit.bor(OFN_FILEMUSTEXIST,OFN_EXPLORER));
		alloc:set(msg:getMsgPtr(),msg:getMsgSize());
		callbackthread["OpenFolder"]=thread;
		LXZAPI_CallSystemAPI("OpenFolder","ui file (.ui;)*.ui;\0\0",alloc);	
		alloc:destroy();

		local file = coroutine.yield();	
	--	local file = "H:\\Demo\\ffmpeg\\ffmpeg.ui";
		--LXZMessageBox("file:"..file);
		if file ~= nil and string.len(file)>0 then						
			local wnd = CLXZWindow:LoadWindow(file);			
			local root = HelperGetRoot();
			local tree = root:GetLXZWindow("ui tree:items");	
			local cls   = root:GetLXZWindow("system:wnd item");			
			tree:ClearChilds();
			add_tree_item(cls, tree,wnd);	
			local child = tree:GetFirstChild();
			LXZMessageBox("child:"..child:GetName());
			reset_tree_position(child, 0);
			wnd:Delete();
		end
	end);	
end

local function OnPropertyMsg_close_dictions(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("dictions");
	wnd:Hide();
	root:GetLXZWindow("head:dictions_btn"):SetState(0);
end

local function  OnPropertyMsg_trigger(window, msg, sender)
	local wnd = sender:GetChild("select");
		
	if wnd:GetState()==0 then
		wnd:SetState(1);
	else
		wnd:SetState(0);
	end
	
	if sender:GetName()=="once" then
		
	elseif sender:GetName()=="end" then
	
	end
end


local function OnPropertyMsg_resolution(window, msg, sender)
	local root = HelperGetRoot();
	local menus = root:GetLXZWindow("head:resolution");
	menus:Hide();
	root:GetLXZWindow("head:resolution_btn"):SetState(0);
	
	local wnd = menus:GetFirstChild();
	while wnd do
		wnd:GetChild("select"):SetState(0);
		wnd=wnd:GetNextSibling();
	end
	
	sender:GetChild("select"):SetState(1);
	local resolution = HelperGetWindowText(sender:GetChild("value"));
	HelperSetWindowText(root:GetLXZWindow("head:resolution_sel"), resolution);	
	local pt = LXZPoint:new_local();
	local wnd=root:GetLXZWindow("canvas:context");
	wnd:GetHotPos(pt, true);
	--LXZMessageBox("LXZAPI_AsyncCallback1:"..resolution);
	if sender:GetName()=="default" then
		--LXZMessageBox("LXZAPI_AsyncCallback1")
		local render = wnd:GetRender("Context");
		local corecfg = render:GetCfg();
		local ctx=corecfg:GetObj("context");
		--LXZMessageBox("LXZAPI_AsyncCallback2")
		HelperCoroutine(function(thread)
			--LXZMessageBox("LXZAPI_AsyncCallback3")
			LXZAPI_AsyncCallback(ctx, thread, [[ local root=HelperGetRoot();return serialize({w=root:GetWidth(),h=root:GetHeight()});]]);
			local str = coroutine.yield();
			if str ~= nil and string.len(str)>0 then
				local res=unserialize(str);
				wnd:SetWidth(res.w);
				wnd:SetHeight(res.h);
			end			
		end);
		
	else
		local _,__,w,h= string.find(resolution, "(%d+)x(%d+)");		
		wnd:SetWidth(w);
		wnd:SetHeight(h);	
		
		local msg0 = CLXZMessage:new_local();
		msg0:int(w);
		msg0:int(h);
		wnd:ProcMessage("OnSetResolution", msg0, wnd);
	end
	wnd:SetHotPos(pt, true);

end

local property_callback ={};
property_callback["tween info:property:repeat:value:arrow"] = OnPropertyMsg_repeat_arrow;
property_callback["tween info:menus:repeat_menus:once"] = OnPropertyMsg_repeat_menus;
property_callback["tween info:menus:repeat_menus:unlimit"] = OnPropertyMsg_repeat_menus;
property_callback["tween info:menus:repeat_menus:user"] = OnPropertyMsg_repeat_menus;
property_callback["tween info:property:reverse:value"] = OnPropertyMsg_reverse_select;

property_callback["tween info:property:erase transition:value:arrow"] = OnPropertyMsg_transition_arrow;
property_callback["tween info:property:erase equation:value:arrow"] = OnPropertyMsg_equation_arrow;
property_callback["tween info:close_btn"] = OnPropertyMsg_close_tween_info;
property_callback["ui tree:head:close_btn"] = OnPropertyMsg_close_ui_tree;
property_callback["ui tree:head:open_btn"] = OnPropertyMsg_open_ui_tree;
property_callback["dictions:close_btn"] = OnPropertyMsg_close_dictions;

property_callback["tween info:property:trigger:once"] = OnPropertyMsg_trigger;
property_callback["tween info:property:trigger:end"] = OnPropertyMsg_trigger;

property_callback["head:resolution:default"] = OnPropertyMsg_resolution;
property_callback["head:resolution:320x568"] = OnPropertyMsg_resolution;
property_callback["head:resolution:384x512"] = OnPropertyMsg_resolution;
property_callback["head:resolution:1024x768"] = OnPropertyMsg_resolution;
property_callback["head:resolution:270x360"] = OnPropertyMsg_resolution;






local function OnPropertyMsg(window, msg, sender)
	local name = sender:GetLongName();
	if property_callback[name] then
		property_callback[name](window, msg, sender);
	end
end

local function OnEquationMenuItem(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Hide();
	wnd:GetLXZWindow("equation_menus"):Hide();
	HelperSetWindowText(root:GetLXZWindow("tween info:property:erase equation:value"), sender:GetName());
end

local function OnTransitionMenuItem(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("tween info:menus");
	wnd:Hide();
	wnd:GetLXZWindow("transition_menus"):Hide();
	HelperSetWindowText(root:GetLXZWindow("tween info:property:erase transition:value"), sender:GetName());
end

local function OnHeadBtnItem(window, msg, sender)	
	local root = HelperGetRoot();		
	if sender:GetName()=="control_btn" then
		if sender:GetState()==0 then
			sender:SetState(1);
		else
			sender:SetState(0);
		end
	elseif sender:GetName()=="ui_tree_btn" then
		if sender:GetState()==0 then
			sender:SetState(1);
			root:GetLXZWindow("ui tree"):Show();
		else
			sender:SetState(0);
			root:GetLXZWindow("ui tree"):Hide();
		end
	elseif sender:GetName()=="tween_info_btn" then
		if sender:GetState()==0 then
			sender:SetState(1);
			root:GetLXZWindow("tween info"):Show();
		else
			sender:SetState(0);
			root:GetLXZWindow("tween info"):Hide();
		end
	elseif sender:GetName()=="dictions_btn" then
		if sender:GetState()==0 then
			sender:SetState(1);
			root:GetLXZWindow("dictions"):Show();
		else
			sender:SetState(0);
			root:GetLXZWindow("dictions"):Hide();
		end
	elseif sender:GetName()=="resolution_btn" then
		if sender:GetState()==0 then
			sender:SetState(1);
			root:GetLXZWindow("head:resolution"):Show();
		else
			sender:SetState(0);
			root:GetLXZWindow("head:resolution"):Hide();
		end
	end
end

local function OnClose(window, msg, sender)
	local corecfg = ICGuiGetLXZCoreCfg();	
	if corecfg.IsEditTool==0 or corecfg.IsEditTool==false then
		--LXZMessageBox("OnClose");
		WM_CLOSE = 0x0010;
		LXZAPI_PostWin32Message(WM_CLOSE, 0, 0);
	end
end

local function OnMinSize(window, msg, sender)
	local corecfg = ICGuiGetLXZCoreCfg();	
	if corecfg.IsEditTool==0 or corecfg.IsEditTool==false then
		--LXZMessageBox("OnMinSize");
		WM_SYSCOMMAND=0x0112;
		SC_MINIMIZE = 0xF020;
		LXZAPI_PostWin32Message(WM_SYSCOMMAND, SC_MINIMIZE, 0);
		sender:SetState(0);
	end
end

local function OnFileMenus(window, msg, sender)
	local root = HelperGetRoot();
	root:GetLXZWindow("head:file_menu:menus"):Show();
end

local function CheckTweenInfo()
	local root = HelperGetRoot();
	local tween_layer = root:GetLXZWindow("canvas:tween layer");
	local start = tween_layer:GetChild("start");
	local end_ = tween_layer:GetChild("end");
	local str = "";
	if start == nil then
		str = str.."start button doesn't  exist";
	end
	
	if end_ == nil then
		str = str.."end button doesn't  exist";
	end
	
	
	
	
end

local function  TraceTweenInfo()
	
	

end

local function ExportTweenInfoToFile(filename,data)
	local dir = LXZAPIGetWritePath();	
	local file = io.open(dir..filename, "w+");
	if file then	
		file:write(data);	
		file:close();
	end
end

local function OnFileMenuItem(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("head:file_menu:menus");
	wnd:Hide();
		
	if sender:GetName()=="new" then
	elseif sender:GetName()=="open" then
	elseif sender:GetName()=="save" then
		if CheckTweenInfo()==false then
			return;
		end
		
		ExportTweenInfo(TraceTweenInfo());
	end
	
end

local function OnTreeIconItem(window, msg, sender)
	local wnd = sender:GetParent();
	local w = wnd:GetChild("childs");
	if w:IsVisible()==true then
		w:Hide();
	else
		w:Show();
	end
	
	local root = HelperGetRoot();
	local tree = root:GetLXZWindow("ui tree:items");	
	reset_tree_position(tree:GetFirstChild(), 0);
	--w:ProcMessage("OnArray", msg, w);
end

local function OnEditWaitTimerOk(window, msg, sender)
	local root = HelperGetRoot();
	local wnd = root:GetLXZWindow("wait timer input");
	wnd:Hide();
	local text = HelperGetWindowText(wnd:GetChild("value"));
	local window=CLXZWindow:FromHandle(wnd:GetAddData());
	if window then
		HelperSetWindowText(window, "µÈ´ý:"..text.."ms");
	end	
end


local event_callback = {}
event_callback ["OnLoad"] = OnLoad;
event_callback ["OnUpdate"] = OnUpdate;
event_callback ["OnWillAddElement"] = OnWillAddElement;
event_callback ["OnCanvasMouseMove"] = OnCanvasMouseMove;
event_callback ["OnCanvasClickUp"] = OnCanvasClickUp;
event_callback ["OnCanvasClickDown"] = OnCanvasClickDown;
event_callback ["OnCanvasKeyDown"] = OnCanvasKeyDown;
event_callback ["OnCanvasDrag"] = OnCanvasDrag;
event_callback ["OnCanvasDBClick"] = OnCanvasDBClick;

event_callback ["OnCursorMove"] = OnCursorMove;
event_callback ["OnDropElement"] = OnDropElement;
event_callback ["OnPropertyMsg"] = OnPropertyMsg;
event_callback ["OnEquationMenuItem"] = OnEquationMenuItem;
event_callback ["OnTransitionMenuItem"] = OnTransitionMenuItem;

event_callback ["OnMinSize"] = OnMinSize;
event_callback ["OnClose"] = OnClose;
event_callback ["OnHeadBtnItem"] =OnHeadBtnItem;
event_callback ["OnFileMenus"] =OnFileMenus;
event_callback ["OnFileMenuItem"] =OnFileMenuItem;
event_callback ["OnTreeIconItem"] =OnTreeIconItem;
event_callback ["OnTreeItemRender"] = OnTreeItemRender;
event_callback ["OnEditWaitTimerOk"] = OnEditWaitTimerOk;

function main_dispacher(window, cmd, msg, sender)
---	LXZAPI_OutputDebugStr("cmd 1:"..cmd);
	if(event_callback[cmd] ~= nil) then
--		LXZAPI_OutputDebugStr("cmd 2:"..cmd);
		event_callback[cmd](window, msg, sender);
	end
end

