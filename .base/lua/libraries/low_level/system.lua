local system = _G.system or {}

local function not_implemented() debug.trace() logn("this function is not yet implemented!") end

do -- memory
	if WINDOWS then
		 
		ffi.cdef([[
		typedef struct _PROCESS_MEMORY_COUNTERS {
		  unsigned long cb;
		  unsigned long PageFaultCount;
		  size_t PeakWorkingSetSize;
		  size_t WorkingSetSize;
		  size_t QuotaPeakPagedPoolUsage;
		  size_t QuotaPagedPoolUsage;
		  size_t QuotaPeakNonPagedPoolUsage;
		  size_t QuotaNonPagedPoolUsage;
		  size_t PagefileUsage;
		  size_t PeakPagefileUsage;
		} PROCESS_MEMORY_COUNTERS, *PPROCESS_MEMORY_COUNTERS;
		int GetProcessMemoryInfo(void* Process, PPROCESS_MEMORY_COUNTERS ppsmemCounters, unsigned long long cb);
		]])
		
		local lib = ffi.load("kernel32")
		local pmc = ffi.new("PROCESS_MEMORY_COUNTERS[1]")
		
		function system.GetMemoryInfo()
			lib.GetProcessMemoryInfo(nil, pmc, sizeof(pmc))
			local pmc = pmc[0]
			
			return {
				page_fault_count = pmc.PageFaultCount,
				peak_working_set_size = pmc.PeakWorkingSetSize,
				working_set_size = pmc.WorkingSetSize,
				qota_peak_paged_pool_usage = pmc.QuotaPeakPagedPoolUsage,
				quota_paged_pool_usage = pmc.QuotaPagedPoolUsage,
				quota_peak_non_paged_pool_usage = pmc.QuotaPeakNonPagedPoolUsage,
				quota_non_paged_pool_usage = pmc.QuotaNonPagedPoolUsage,
				page_file_usage = pmc.PagefileUsage,
				peak_page_file_usage = pmc.PeakPagefileUsage,
			}			
		end
	end
	
	if LINUX then
		system.GetMemoryInfo = not_implemented
	end
end

do -- editors
	local editors = {
		{	
			-- if you have sublime installed you most likely don't have any other editor installed
			name = "sublime",
			args = "%PATH%:%LINE%",
		},
		{
			name = "notepad2",
			args = "/g %LINE% %PATH%",
		},
		{
			name = "notepad++",
			args = "%PATH% -n%LINE%",
		},
		{
			name = "notepad",
			args = "/A %PATH%",
		},
	}

	function system.FindFirstEditor(os_execute, with_args)
		for k, v in pairs(editors) do
			if WINDOWS then
				local path = system.GetRegistryValue("ClassesRoot/Applications/"..v.name..".exe/shell/open/command/default")
				
				if path then
					if os_execute then
						path = path:match([[(".-")]])
						path = "start \"\" " .. path
					else
						path = path:match([["(.-)"]])
					end
					
					if with_args and v.args then 
						path = path .. " " .. v.args
					end
					
					return path
				end
			end
		end
	end
end

do -- message box
	local set = not_implemented
	
	if WINDOWS then		
		ffi.cdef("int MessageBoxA(void *w, const char *txt, const char *cap, int type);")
		
		set = function(title, message)
			ffi.C.MessageBoxA(nil, message, title, 0)
		end
	end
	
	system.MessageBox = set
end

do -- title
	local set_title
	if WINDOWS then
		ffi.cdef("int SetConsoleTitleA(const char* blah);")

		set_title = function(str)
			return ffi.C.SetConsoleTitleA(str)
		end
	end

	if LINUX then
		set_title = function(str)
			return io.old_write and io.old_write('\27]0;', str, '\7') or nil
		end
	end
	
	system.SetWindowTitleRaw = set_title
	
	local titles = {}
	local str = ""
	local last = 0
	local last_title
	
	local lasttbl = {}
	
	function system.SetWindowTitle(title, id)
		local time = os.clock()
		
		if not lasttbl[id] or lasttbl[id] < time then
			if id then
				titles[id] = title
				str = "| "
				for k,v in pairs(titles) do
					str = str ..  v .. " | "
				end
				if str ~= last_title then
					system.SetWindowTitleRaw(str)
				end
			else
				str = title
				if str ~= last_title then
					system.SetWindowTitleRaw(title)
				end
			end
			last_title = str
			lasttbl[id] = os.clock() + 0.05
		end
	end
	
	function system.GetWindowTitle()
		return str
	end
end

do -- cursor
	local set = not_implemented
	local get = not_implemented

	if WINDOWS then
		ffi.cdef[[
			void* SetCursor(void *);
			void* LoadCursorA(void*, uint16_t);
		]]
		
		local lib = ffi.load("user32.dll")
		local cache = {}

		
		--[[arrow = IDC_ARROW, 
		ibeam = IDC_IBEAM, 
		wait = IDC_WAIT, 
		cross = IDC_CROSS, 
		uparrow = IDC_UPARROW, 
		size = IDC_SIZE, 
		icon = IDC_ICON, 
		sizenwse = IDC_SIZENWSE, 
		sizenesw = IDC_SIZENESW, 
		sizewe = IDC_SIZEWE, 
		sizens = IDC_SIZENS, 
		sizeall = IDC_SIZEALL, 
		no = IDC_NO, 
		hand = IDC_HAND, 
		appstarting = IDC_APPSTARTING, 		
		help = IDC_HELP,]]
		
		e.IDC_ARROW = 32512
		e.IDC_IBEAM = 32513
		e.IDC_WAIT = 32514
		e.IDC_CROSS = 32515
		e.IDC_UPARROW = 32516
		e.IDC_SIZE = 32640
		e.IDC_ICON = 32641
		e.IDC_SIZENWSE = 32642
		e.IDC_SIZENESW = 32643
		e.IDC_SIZEWE = 32644
		e.IDC_SIZENS = 32645
		e.IDC_SIZEALL = 32646
		e.IDC_NO = 32648
		e.IDC_HAND = 32649
		e.IDC_APPSTARTING = 32650
		e.IDC_HELP = 32651
		
		local current
		
		local last 
		
		set = function(id)
			id = id or e.IDC_ARROW
			cache[id] = cache[id] or lib.LoadCursorA(nil, id)
			
			--if last ~= id then
				current = id
				lib.SetCursor(cache[id])
			--	last = id
			--end
		end
		
		get = function()
			return current
		end
	else
		get = function() end
		set = get
	end
	
	system.SetCursor = set
	system.GetCursor = get
	
end

do -- dll paths
	local set, get = not_implemented, not_implemented
	
	if WINDOWS then		
		ffi.cdef[[
			int SetDllDirectoryA(const char *path);
			unsigned long GetDllDirectoryA(unsigned long length, char *path);
		]]
		
		set = function(path)
			ffi.C.SetDllDirectoryA(path or "")
		end
		
		local str = ffi.new("char[1024]")
		
		get = function()
			ffi.C.GetDllDirectoryA(1024, str)
			
			return ffi.string(str)
		end
	end
	
	if LINUX then
		set = function(path)
			logn("seting LD_LIBRARY_PATH to ", path)
			os.setenv("LD_LIBRARY_PATH", path)
		end
		
		get = function()
			return os.getenv("LD_LIBRARY_PATH") or ""
		end
	end
	
	system.SetSharedLibraryPath = set
	system.GetSharedLibraryPath = get
end

do -- fonts
	local get = not_implemented
	
	if WINDOWS then
		--[==[ffi.cdef[[
				
		typedef struct LOGFONT {
		  long  lfHeight;
		  long lfWidth;
		  long  lfEscapement;
		  long  lfOrientation;
		  long  lfWeight;
		  char  lfItalic;
		  char  lfUnderline;
		  char  lfStrikeOut;
		  char  lfCharSet;
		  char  lfOutPrecision;
		  char  lfClipPrecision;
		  char  lfQuality;
		  char  lfPitchAndFamily;
		  char lfFaceName[LF_FACESIZE];
		} LOGFONT;

		
		int EnumFontFamiliesEx(void *, LOGFONT *)
		]]]==]
	
		get = function()
			
		end
	elseif LINUX then
		ffi.cdef([[
			typedef struct {} Display;
			Display* XOpenDisplay(const char*);
			void XCloseDisplay(Display*);
			char** XListFonts(Display* display, const char* pattern, int max_names, int* actual_names);
		]])

		local X11 = ffi.load("X11")

		local display = X11.XOpenDisplay(nil)

		if display == nil then
			print("cricket")
			return
		end

		local count = ffi.new("int[1]")
		local names = X11.XListFonts(display, "*", 65535, count)
		count = count[0]

		for i = 1, count do
			local name = ffi.string(names[i - 1])
		end

		X11.XCloseDisplay(display)
	end

	system.GetInstalledFonts = get

end

do -- registry
	local set = not_implemented
	local get = not_implemented

	if WINDOWS then
		ffi.cdef([[
			typedef unsigned HKEY;
			long __stdcall RegGetValueA(HKEY, const char*, const char*, unsigned, unsigned*, void*, unsigned*);
		]])

		local advapi = ffi.load("advapi32")

		local ERROR_SUCCESS = 0
		local HKEY_CLASSES_ROOT  = 0x80000000
		local HKEY_CURRENT_USER = 0x80000001
		local HKEY_LOCAL_MACHINE = 0x80000002
		local HKEY_CURRENT_CONFIG = 0x80000005

		local RRF_RT_REG_SZ = 0x00000002
	
		local translate = {
			HKEY_CLASSES_ROOT  = 0x80000000,
			HKEY_CURRENT_USER = 0x80000001,
			HKEY_LOCAL_MACHINE = 0x80000002,
			HKEY_CURRENT_CONFIG = 0x80000005,
			
			ClassesRoot  = 0x80000000,
			CurrentUser = 0x80000001,
			LocalMachine = 0x80000002,
			CurrentConfig = 0x80000005,
		}
		
		get = function(str)
			local where, key1, key2 = str:match("(.-)/(.+)/(.*)")
			
			if where then
				where, key1 = str:match("(.-)/(.+)/")
			end
									
			where = translate[where] or where
			key1 = key1:gsub("/", "\\")
			key2 = key2 or ""
			
			if key2 == "default" then key2 = nil end
			
			local value = ffi.new("char[4096]")
			local value_size = ffi.new("unsigned[1]")
			value_size[0] = 4096
						
			local err = advapi.RegGetValueA(where, key1, key2, RRF_RT_REG_SZ, nil, value, value_size)
			
			if err ~= ERROR_SUCCESS then
				return
			end

			return ffi.string(value)
		end
	end
	
	if LINUX then
		-- return empty values
	end
	
	system.GetRegistryValue = get
	system.SetRegistryValue = set
end

do 
local get = not_implemented
	
	if WINDOWS then
		ffi.cdef("int GetTickCount();")
		
		get = function() return ffi.C.GetTickCount() end
	end
	
	if LINUX then
		ffi.cdef[[	
			typedef long time_t;
			typedef long suseconds_t;

			struct timezone {
				int tz_minuteswest;     /* minutes west of Greenwich */
				int tz_dsttime;         /* type of DST correction */
			};
			
			struct timeval {
				time_t      tv_sec;     /* seconds */
				suseconds_t tv_usec;    /* microseconds */
			};
			
			int gettimeofday(struct timeval *tv, struct timezone *tz);
		]]
		
		local temp = ffi.new("struct timeval[1]")
		get = function() ffi.C.gettimeofday(temp, nil) return temp[0].tv_usec*100 end
	end
	
	system.GetTickCount = get
end

do -- time in ms
	local get = not_implemented
	
	if WINDOWS then
		ffi.cdef("int timeGetTime();")
		
		get = function() return ffi.C.timeGetTime() end
	end
	
	if LINUX then
		ffi.cdef[[	
			int gettimeofday(struct timeval *tv, struct timezone *tz);
		]]
		
		local temp = ffi.new("struct timeval[1]")
		get = function() ffi.C.gettimeofday(temp, nil) return temp[0].tv_usec*100 end
	end
	
	system.GetTimeMS = get
end

do -- sleep
	local sleep = not_implemented
	
	if WINDOWS then
		ffi.cdef("void Sleep(int ms)")
		sleep = function(ms) ffi.C.Sleep(ms) end
	end

	if LINUX then
		ffi.cdef("void usleep(unsigned int ns)")
		sleep = function(ms) ffi.C.usleep(ms*1000) end
	end
	
	system.Sleep = sleep
end

do -- clipboard
	local set = not_implemented
	local get = not_implemented
		
	system.SetClipboard = set
	system.GetClipboard = get	
end

do -- transparent window
	local set = not_implemented

	if WINDOWS then
		set = function(window, b)
			-- http://stackoverflow.com/questions/4052940/how-to-make-an-opengl-rendering-context-with-transparent-background
		
			ffi.cdef([[
				typedef unsigned char BYTE;
				typedef unsigned short WORD;
				typedef unsigned long DWORD;
				
				typedef struct {
					WORD  nSize;
					WORD  nVersion;
					DWORD dwFlags;
					BYTE  iPixelType;
					BYTE  cColorBits;
					BYTE  cRedBits;
					BYTE  cRedShift;
					BYTE  cGreenBits;
					BYTE  cGreenShift;
					BYTE  cBlueBits;
					BYTE  cBlueShift;
					BYTE  cAlphaBits;
					BYTE  cAlphaShift;
					BYTE  cAccumBits;
					BYTE  cAccumRedBits;
					BYTE  cAccumGreenBits;
					BYTE  cAccumBlueBits;
					BYTE  cAccumAlphaBits;
					BYTE  cDepthBits;
					BYTE  cStencilBits;
					BYTE  cAuxBuffers;
					BYTE  iLayerType;
					BYTE  bReserved;
					DWORD dwLayerMask;
					DWORD dwVisibleMask;
					DWORD dwDamageMask;
				} PIXELFORMATDESCRIPTOR;
			
				typedef struct {
					int x,y,w,h;
				} HRGN;
				
				typedef struct {
					unsigned long dwFlags;
					int  fEnable;
					HRGN  hRgnBlur;
					int  fTransitionOnMaximized;
				} DWM_BLURBEHIND;
				
				void* GetDC(void*);
				
				int ChoosePixelFormat(
				  void *,
				  const PIXELFORMATDESCRIPTOR *ppfd
				);
			
				long GetWindowLongA(void*, int);
				long SetWindowLongA(void*, int, long);
				long DwmEnableBlurBehindWindow(void*, DWM_BLURBEHIND);
								
				HRGN CreateRectRgn(int,int,int,int);
				int SetPixelFormat(
				  void *hdc,
				  int iPixelFormat,
				  const PIXELFORMATDESCRIPTOR *ppfd
				);
				DWORD GetLastError();
			]])
			
			local GWL_STYLE = -16
			local WS_OVERLAPPEDWINDOW = 0x00CF0000
			local WS_POPUP = 0x80000000
			local DWM_BB_ENABLE = 0x00000001
			local DWM_BB_BLURREGION = 0x00000002
			
			local lib = ffi.load("dwmapi.dll")
			
			local style = ffi.C.GetWindowLongA(window, GWL_STYLE)
			style = bit.band(style, bit.bnot(WS_OVERLAPPEDWINDOW))
			style = bit.bor(style, WS_POPUP)
			
			ffi.C.SetWindowLongA(window, GWL_STYLE, style)
			
			local bb = ffi.new("DWM_BLURBEHIND",0)
			bb.dwFlags = bit.bor(DWM_BB_ENABLE, DWM_BB_BLURREGION)
			bb.fEnable = true
			bb.hRgnBlur = ffi.load("Gdi32.dll").CreateRectRgn(0,0,1,1)
			bb.fTransitionOnMaximized = 0
			lib.DwmEnableBlurBehindWindow(window, bb)		
			
			local PFD_TYPE_RGBA = 0
			local PFD_MAIN_PLANE = 0
			local PFD_DOUBLEBUFFER = 1
			local PFD_DRAW_TO_WINDOW = 4
			local PFD_SUPPORT_OPENGL = 32
			local PFD_SUPPORT_COMPOSITION = 0x00008000
			
			local pfd = ffi.new("PIXELFORMATDESCRIPTOR", {
				ffi.sizeof("PIXELFORMATDESCRIPTOR"),
				1,                                -- Version Number
				bit.bor(
					PFD_DRAW_TO_WINDOW      ,     -- Format Must Support Window
					PFD_SUPPORT_OPENGL      ,     -- Format Must Support OpenGL
					PFD_SUPPORT_COMPOSITION       -- Format Must Support Composition
				),
				PFD_DOUBLEBUFFER,                 -- Must Support Double Buffering
				PFD_TYPE_RGBA,                    -- Request An RGBA Format
				32,                               -- Select Our Color Depth
				0, 0, 0, 0, 0, 0,                 -- Color Bits Ignored
				8,                                -- An Alpha Buffer
				0,                                -- Shift Bit Ignored
				0,                                -- No Accumulation Buffer
				0, 0, 0, 0,                       -- Accumulation Bits Ignored
				24,                               -- 16Bit Z-Buffer (Depth Buffer)
				8,                                -- Some Stencil Buffer
				0,                                -- No Auxiliary Buffer
				PFD_MAIN_PLANE,                   -- Main Drawing Layer
				0,                                -- Reserved
				0, 0, 0                           -- Layer Masks Ignored
			})
			
			local hdc = ffi.C.GetDC(window)
			print(ffi.C.GetLastError(), window, hdc)
			local pxfmt = ffi.load("Gdi32.dll").ChoosePixelFormat(hdc, pfd)
			ffi.load("Gdi32.dll").SetPixelFormat(hdc, pxfmt, pfd)
			gl.Enable(e.GL_BLEND)
			gl.BlendFunc(e.GL_SRC_ALPHA, e.GL_ONE_MINUS_SRC_ALPHA)
			
			render.SetClearColor(0,0,0,0)
		end
	end

	system.EnableWindowTransparency = set
end

function system.DebugJIT(b)
	if b then
		jit.v.on(R"%DATA%/logs/jit_verbose_output.txt")
	else
		jit.v.off(R"%DATA%/logs/jit_verbose_output.txt")
	end
end


function system.Restart()
	lfs.chdir("../../../../") 
	os.execute("launch.bat") 
	os.exit()
end

-- this should be used for xpcall
local suppress = false
local last_openfunc = 0
function system.OnError(msg, ...)
	msg = msg or "no error"
	if suppress then logn("supressed error: ", msg, ...) for i = 3, 100 do local t = debug.getinfo(i) if t then table.print(t) else break end end return end
	suppress = true
	if LINUX and msg == "interrupted!\n" then return end
	
	if event.Call("OnLuaError", msg) == false then return end
	
	if msg:find("stack overflow") then
		logn(msg)
		table.print(debug.getinfo(3))
		return
	end
	
	logn("STACK TRACE:")
	logn("{")
	
	local base_folder = e.ROOT_FOLDER:gsub("%p", "%%%1")
	local data = {}
		
	for level = 3, 100 do
		local info = debug.getinfo(level)
		if info then
			if info.currentline >= 0 then			
				local args = {}
				
				for arg = 1, info.nparams do
					local key, val = debug.getlocal(level, arg)
					if type(val) == "table" then
						val = tostring(val)
					else
						val = luadata.ToString(val)
						if val and #val > 200 then
							val = val:sub(0, 200) .. "...."
						end
					end
					table.insert(args, ("%s = %s"):format(key, val))
				end
				
				info.arg_line = table.concat(args, ", ")
				
				local source = info.short_src or ""
				source = source:gsub(base_folder, ""):trim()
				info.source = source
				info.name = info.name or "unknown"
				
				table.insert(data, info)
			end
		else
			break
		end
    end
	
	local function resize_field(tbl, field)
		local length = 0
		
		for _, info in pairs(tbl) do
			local str = tostring(info[field])
			if str then
				if #str > length then
					length = #str
				end
				info[field] = str
			end
		end
		
		for _, info in pairs(tbl) do
			local str = info[field]
			if str then				
				local diff = length - #str
				
				if diff > 0 then
					info[field] = str .. (" "):rep(diff)
				end
			end
		end
	end
	
	table.insert(data, {currentline = "LINE:", source = "SOURCE:", name = "FUNCTION:", arg_line = " ARGUMENTS "})
	
	resize_field(data, "currentline")
	resize_field(data, "source")
	resize_field(data, "name")
	
	for _, info in npairs(data) do
		logf("  %s   %s   %s(%s)\n", info.currentline, info.source, info.name, info.arg_line)
	end

	logn("}")
	local source, _msg = msg:match("(.+): (.+)")
	
	
	if source then
		source = source:trim()
		
		local info
		
		-- this should be replaced with some sort of configuration
		-- gl.lua never shows anything useful but the level above does..			
		if source:find("ffi_bind") then
			info = debug.getinfo(4)
		else
			info = debug.getinfo(2)
		end
			
		if last_openfunc < os.clock() then
			debug.openfunction(info.func, info.currentline)
			last_openfunc = os.clock() + 3
		else
			--logf("debug.openfunction(%q)\n", source)
		end
		
		logn(source)
		logn(_msg:trim())
	else
		logn(msg)
	end
	
	logn("")
	
	suppress = false
end

if system.lua_environment_sockets then
	for key, val in pairs(system.lua_environment_sockets) do
		utilities.SafeRemove(val)
	end
end

function system.StartLuaInstance(...)
	local args = {...}
	local arg_line = ""
	
	for k,v in pairs(args) do
		arg_line = arg_line .. luadata.ToString(v)
		if #args ~= k then
			arg_line = arg_line .. ", "
		end
	end
	
	arg_line = arg_line:gsub('"', "'")
	
	local arg = ([[-e ARGS={%s}loadfile('%sinit.lua')()]]):format(arg_line, e.ROOT_FOLDER .. "/.base/lua/")
		
	if WINDOWS then
		os.execute([[start "" "luajit" "]] .. arg .. [["]])
	elseif LINUX then
		os.execute([[luajit "]] .. arg .. [[" &]])
	end
end

system.lua_environment_sockets = {}

function system.CreateLuaEnvironment(title, globals, id)	
	check(globals, "table", "nil")
	id = id or title
	
	local socket = system.lua_environment_sockets[id] or NULL
	
	if socket:IsValid() then 
		socket:Send("exit")
		socket:Remove()
	end
	
	local socket = luasocket.Server()
	socket:Host("*", 0)
					
	system.lua_environment_sockets[id] = socket
	
	local arg = ""
		
	globals = globals or {}
	
	globals.PLATFORM = _G.PLATFORM or globals.PLATFORM
	globals.PORT = socket:GetPort()
	globals.CREATED_ENV = true
	globals.TITLE = tostring(title)

	for key, val in pairs(globals) do
		arg = arg .. key .. "=" .. luadata.ToString(val) .. ";"
	end	
	
	arg = arg:gsub([["]], [[']])	
	arg = ([[-e %sloadfile('%sinit.lua')()]]):format(arg, e.ROOT_FOLDER .. "/.base/lua/")
		
	if WINDOWS then
		os.execute([[start "" "luajit" "]] .. arg .. [["]])
	elseif LINUX then
		os.execute([[luajit "]] .. arg .. [[" &]])
	end
	
	local env = {}
	
	function env:OnReceive(line)
		local func, msg = loadstring(line)
		if func then
			local ok, msg = xpcall(func, system.OnError) 
			if not ok then
				logn("runtime error:", client, msg)
			end
		else
			logn("compile error:", client, msg)
		end
	end
	
	local queue = {}
		
	function env:Send(line)
		if not socket:HasClients() then
			table.insert(queue, line)
		else
			socket:Broadcast(line, true)
		end
	end
	
	function env:Remove()
		self:Send("os.exit()")
		socket:Remove()
	end
	
	socket.OnClientConnected = function(self, client)	
		for k,v in pairs(queue) do
			socket:Broadcast(v, true)
		end
		
		queue = {}
		
		return true 
	end
		
	socket.OnReceive = function(self, line)
		env:OnReceive(line)
	end
		
	env.socket = socket
	
	return env
end

function system.CreateConsole(title)
	if CONSOLE then return logn("tried to create a console in a console!!!") end
	local env = system.CreateLuaEnvironment(title, {CONSOLE = true})
	
	env:Send([[
		local __stop__
		
		local function clear() 
			logn(("\n"):rep(1000)) -- lol
		end
				
		local function exit()
			__stop__ = true
			os.exit()
		end
		
		clear()
		
		ENV_SOCKET.OnClose = function() exit() end

		event.AddListener("OnConsoleEnvReceive", TITLE, function()
			::again::
			
			local str = io.read()
			
			if str == "exit" then
				exit()
			elseif str == "clear" then
				clear()
			end

			if str and #str:trim() > 0 then
				ENV_SOCKET:Send(str, true)
			else
				goto again
			end
		end)
		
		event.AddListener("ShutDown", TITLE, function()
			ENV_SOCKET:Remove()
		end)
	]])	
		
	event.AddListener("OnPrint", title .. "_console_output", function(...)
		local line = tostring_args(...)
		env:Send(string.format("logn(%q)", line))
	end)
	
		
	function env:Remove()
		self:Send("os.exit()")
		utilities.SafeRemove(self.socket)
		event.RemoveListener("OnPrint", title .. "_console_output")
	end
	
	
	return env
end

return system
