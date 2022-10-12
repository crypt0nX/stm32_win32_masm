.486
.model flat,stdcall
option casemap:none

;///////////////////////////////////////////////////////////////////////////////
; Include文件定义
;///////////////////////////////////////////////////////////////////////////////
include windows.inc
include user32.inc
include kernel32.inc
include masm32.inc

includelib user32.lib
includelib kernel32.lib
includelib masm32.lib
include \masm32\macros\macros.asm
;///////////////////////////////////////////////////////////////////////////////
; EQU 定义
;///////////////////////////////////////////////////////////////////////////////
ICO_MAIN 	equ 103;图标
DLG_MAIN 	equ 101
IDM_ABOUT 	equ 40001
IDM_EXIT	equ 40002
IDC_COMBO1  equ 1001 ;串口
IDC_COMBO2  equ 1003 ;波特率
IDC_COMBO3  equ 1004 ;校验位
IDC_COMBO4  equ 1005 ;数据位
IDC_COMBO5  equ 1006 ;停止位
IDC_LIST1   equ 1008 ;聊天内容
IDC_EDIT   equ 1009 ;聊天输入框
IDC_BTN_OPEN equ 1011 ;打开串口按钮


BUTTON_RED equ 2001;红色按钮
BUTTON_GREEN equ 2002;绿色按钮
BUTTON_BLUE equ 2003;蓝色按钮
BUTTON_WHITE equ 2004;白色按钮
BUTTON_YELLOW equ 2005;黄色按钮
BUTTON_PURPLE equ 2006;紫色按钮
BUTTON_CYAN equ 2007;青色按钮
BUTTON_DARK equ 2008;暗色按钮

BUTTON_SYNC_TIME equ 2009;暗色按钮
;///////////////////////////////////////////////////////////////////////////////
; 数据段
;///////////////////////////////////////////////////////////////////////////////
.data
Parity	BYTE EVENPARITY,ODDPARITY,NOPARITY,MARKPARITY,SPACEPARITY
szFromatTime db  'P6%02d%02d%02d', 0


.data?
hInstance 	dd ?
hIcon 		dd ?
hWinMain 	dd ?
hCom		dd ? ;串口句柄
g_bOpened		dd ? ;是否打开串口
hCloseEvent dd ? ;串口关闭事件
g_olRead	OVERLAPPED <>
g_olWait	OVERLAPPED <>
g_olWrite	OVERLAPPED <>
g_hListBox	dd ? ;
sysTime SYSTEMTIME <>



;///////////////////////////////////////////////////////////////////////////////
; 代码段
;///////////////////////////////////////////////////////////////////////////////
.code
_GetLastErrorMsg proc
	local @szError[256]:CHAR
	local @dwError
	invoke GetLastError
	mov @dwError,eax
	invoke FormatMessage,FORMAT_MESSAGE_FROM_SYSTEM,NULL,@dwError,0,addr @szError,sizeof @szError,NULL
	invoke MessageBox,hWinMain,addr @szError,CTXT("错误"),MB_ICONERROR
	Ret
_GetLastErrorMsg EndP
;初始化
_Init proc
	local @hCombo
	invoke	LoadIcon,hInstance,ICO_MAIN
	;设置图标
	mov hIcon,eax
	invoke	SendMessage,hWinMain,WM_SETICON,ICON_BIG,hIcon
	;初始化串口设置
	;串口
	invoke GetDlgItem,hWinMain,IDC_COMBO1
	mov @hCombo,eax
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("COM1")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("COM2")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("COM3")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("COM4")
	invoke SendMessage,@hCombo,CB_SETCURSEL,0,0	;默认选择COM1
	;波特率
	invoke GetDlgItem,hWinMain,IDC_COMBO2
	mov @hCombo,eax
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("75")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("110")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("134")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("150")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("300")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("600")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("1200")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("1800")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("2400")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("4800")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("7200")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("9600")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("14400")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("19200")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("38400")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("56000")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("57600")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("115200")
	invoke SendMessage,@hCombo,CB_SETCURSEL,17,0	;默认选择115200
	;校验位
	invoke GetDlgItem,hWinMain,IDC_COMBO3
	mov @hCombo,eax
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("偶")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("奇")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("无")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("标志")	
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("空格")
	invoke SendMessage,@hCombo,CB_SETCURSEL,2,0	;默认选择NO
	;数据位
	invoke GetDlgItem,hWinMain,IDC_COMBO4
	mov @hCombo,eax
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("4")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("5")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("6")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("7")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("8")
	invoke SendMessage,@hCombo,CB_SETCURSEL,4,0	;默认选择NO
	;停止位
	invoke GetDlgItem,hWinMain,IDC_COMBO5
	mov @hCombo,eax
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("1")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("1.5")
	invoke SendMessage,@hCombo,CB_ADDSTRING,0,CTXT("2")
	invoke SendMessage,@hCombo,CB_SETCURSEL,0,0	;默认选择NO
	
	;关闭事件
	invoke CreateEvent,\
		NULL,\ 	;default security attributes
		FALSE,\ ;auto reset event
		FALSE,\	;not signaled
		NULL	;no name
	mov hCloseEvent,eax
	
	;初始化Overlapped参数
	;读
	invoke RtlZeroMemory,addr g_olRead,sizeof g_olRead
	invoke CreateEvent,\
		NULL,\ 	;default security attributes
		TRUE,\ ;auto reset event
		FALSE,\	;not signaled
		NULL	;no name
	mov g_olRead.hEvent,eax
	
	;等待
	invoke RtlZeroMemory,addr g_olWait,sizeof g_olWait
	invoke CreateEvent,\
		NULL,\ 	;default security attributes
		TRUE,\ ;auto reset event
		FALSE,\	;not signaled
		NULL	;no name
	mov g_olWait.hEvent,eax
	
	;写
	invoke RtlZeroMemory,addr g_olWrite,sizeof g_olWrite
	invoke CreateEvent,\
		NULL,\ 	;default security attributes
		TRUE,\ ;auto reset event
		TRUE,\	;not signaled
		NULL	;no name
	mov g_olWrite.hEvent,eax
	
	mov g_bOpened,FALSE
	
	invoke GetDlgItem,hWinMain,IDC_LIST1
	mov g_hListBox,eax
	
	Ret
_Init EndP

;///////////////////////////////////////////////////////////////////////////////
;处理数据
;///////////////////////////////////////////////////////////////////////////////
_HandleData proc _lpBuffer
	invoke SendMessage,g_hListBox,LB_ADDSTRING,0,_lpBuffer
	Ret
_HandleData EndP

;///////////////////////////////////////////////////////////////////////////////
;读数据
;///////////////////////////////////////////////////////////////////////////////
_ReadData proc
	local @inbuffer[100]:BYTE
	local @dwErrFlag,@nBytesRead
	local @cs:COMSTAT
	
	invoke ClearCommError,hCom,addr @dwErrFlag,addr @cs
	.if @dwErrFlag
		invoke PurgeComm,hCom,PURGE_RXABORT or PURGE_RXCLEAR
		call _GetLastErrorMsg
		ret
	.endif	
	.if @cs.cbInQue
		invoke RtlZeroMemory,addr @inbuffer,sizeof @inbuffer
		invoke ReadFile,hCom,addr @inbuffer,@cs.cbInQue,addr @nBytesRead,addr g_olRead
		.if eax
			invoke _HandleData,addr @inbuffer
		.else
			invoke GetLastError
			.if eax==ERROR_IO_PENDING
				invoke GetOverlappedResult,hCom,addr g_olRead,addr @nBytesRead,TRUE
			.else
				call _GetLastErrorMsg
			.endif
		.endif
	.endif
	Ret
_ReadData EndP

;///////////////////////////////////////////////////////////////////////////////
;写数据
;///////////////////////////////////////////////////////////////////////////////
_WriteData proc _lpBuffer,_nSize
	local @nBytesWritten
	invoke WaitForSingleObject,g_olWrite.hEvent,2000
	.if eax==WAIT_TIMEOUT ;发送超时?
		ret
	.endif
	invoke WriteFile,hCom,_lpBuffer,_nSize,addr @nBytesWritten,addr g_olWrite
	.if !eax
		invoke GetLastError
		.if eax==ERROR_IO_PENDING
			invoke GetOverlappedResult,hCom,addr g_olWrite,addr @nBytesWritten,TRUE
		.else
			call _GetLastErrorMsg
		.endif
	.else
		mov eax,@nBytesWritten
	.endif
	Ret
_WriteData EndP

;///////////////////////////////////////////////////////////////////////////////
;读写数据线程
;///////////////////////////////////////////////////////////////////////////////
_ReadThread proc _lParam	
	local @nBytesRead,@dwEvent,@dwError
	local @cs:COMSTAT
	
	.while g_bOpened		
		invoke WaitCommEvent,hCom,addr @dwEvent,addr g_olWait
		.if !eax
			invoke GetLastError
			.if eax==ERROR_IO_PENDING
				invoke GetOverlappedResult,hCom,addr g_olWait,addr @nBytesRead,TRUE
			.else
				call _GetLastErrorMsg
				.break
			.endif
		.endif
		.if (@dwEvent&EV_RXCHAR)
			call _ReadData
		.else
			invoke ClearCommError,hCom,addr @dwError,addr @cs
			.if @dwError
				invoke PurgeComm,hCom,PURGE_RXABORT or PURGE_RXCLEAR ;丢弃错误的输入
			.endif
		.endif
	.endw
	invoke SetEvent,hCloseEvent	
	Ret
_ReadThread EndP

;///////////////////////////////////////////////////////////////////////////////
;打开串口
_OpenCom proc uses esi
	local @hCombo,@index,@hButton
	local @szCom[20]:CHAR
	local @dwThreadID
	local @to:COMMTIMEOUTS
	local @dcb:DCB
	local @szTmp[30]:CHAR
	local @Parity:BYTE
	
	invoke GetDlgItem,hWinMain,IDC_BTN_OPEN
	mov @hButton,eax
	invoke GetDlgItem,hWinMain,IDC_COMBO1
	mov @hCombo,eax
		
	.if g_bOpened	;已打开?
		invoke EnableWindow,@hCombo,TRUE
		invoke SetWindowText,@hButton,CTXT("打开")
		call _CloseCom
	.else
		invoke SendMessage,@hCombo,CB_GETCURSEL,0,0
		mov @index,eax
		invoke RtlZeroMemory,addr @szCom,sizeof @szCom
		invoke SendMessage,@hCombo,CB_GETLBTEXT,@index,addr @szCom
		
		invoke CreateFile,addr @szCom,\
			GENERIC_READ OR GENERIC_WRITE,\
			0,\
			NULL,\
			OPEN_EXISTING,\
			FILE_FLAG_OVERLAPPED,\
			NULL
		mov hCom,eax
		.if eax == INVALID_HANDLE_VALUE
			call _GetLastErrorMsg
		.else
			;更改按钮状态
			invoke EnableWindow,@hCombo,FALSE
			invoke SetWindowText,@hButton,CTXT("关闭")
			mov g_bOpened,TRUE
			invoke SetCommMask,hCom,EV_RXCHAR ;设置事件驱动类型
			invoke SetupComm,hCom,1024,512 ;设置输入、输出缓冲区的大小
			invoke PurgeComm,hCom,PURGE_TXABORT+PURGE_RXABORT+PURGE_TXCLEAR+PURGE_RXCLEAR ;清干净输入、输出缓冲区
			;超时设置
			invoke RtlZeroMemory,addr @to,sizeof @to
			mov @to.ReadTotalTimeoutMultiplier,5
			mov @to.ReadTotalTimeoutConstant,1000
			invoke SetCommTimeouts,hCom,addr @to
			;设置其他
			invoke RtlZeroMemory,addr @dcb,sizeof @dcb
			invoke GetCommState,hCom,addr @dcb
			;波特率
			invoke GetDlgItem,hWinMain,IDC_COMBO2
			mov @hCombo,eax
			invoke SendMessage,@hCombo,CB_GETCURSEL,0,0
			mov @index,eax
			invoke RtlZeroMemory,addr @szTmp,sizeof @szTmp
			invoke SendMessage,@hCombo,CB_GETLBTEXT,@index,addr @szTmp			
			invoke atol,addr @szTmp
			mov @dcb.BaudRate,eax
			;校验位
			invoke GetDlgItem,hWinMain,IDC_COMBO2
			mov @hCombo,eax
			invoke SendMessage,@hCombo,CB_GETCURSEL,0,0
			mov @index,eax
			.if eax==0
				mov @dcb.Parity,EVENPARITY
			.elseif eax==1
				mov @dcb.Parity,ODDPARITY
			.elseif eax==2
				mov @dcb.Parity,NOPARITY
			.elseif eax==3
				mov @dcb.Parity,MARKPARITY
			.elseif eax==4
				mov @dcb.Parity,SPACEPARITY
			.endif
			;数据位
			invoke GetDlgItem,hWinMain,IDC_COMBO4
			mov @hCombo,eax
			invoke SendMessage,@hCombo,CB_GETCURSEL,0,0
			mov @index,eax
			
			.if eax==0
				mov @dcb.ByteSize,4
			.elseif eax==1
				mov @dcb.ByteSize,5
			.elseif eax==2
				mov @dcb.ByteSize,6
			.elseif eax==3
				mov @dcb.ByteSize,7
			.elseif eax==4
				mov @dcb.ByteSize,8
			.endif
			
			;停止位
			invoke GetDlgItem,hWinMain,IDC_COMBO5
			mov @hCombo,eax
			invoke SendMessage,@hCombo,CB_GETCURSEL,0,0
			mov @index,eax
			.if eax==0
				mov @dcb.StopBits,ONESTOPBIT
			.elseif eax==1
				mov @dcb.StopBits,ONE5STOPBITS
			.elseif eax==2
				mov @dcb.StopBits,TWOSTOPBITS			
			.endif			
			invoke SetCommState,hCom,addr @dcb
			
			;创建接收线程
			invoke ResetEvent,hCloseEvent
			invoke CreateThread,NULL,0,offset _ReadThread,NULL,NULL,addr @dwThreadID
		.endif
	.endif
	
	Ret
_OpenCom EndP
;///////////////////////////////////////////////////////////////////////////////
;关闭
_CloseCom proc
	.if g_bOpened
		mov g_bOpened,FALSE
		invoke SetCommMask,hCom,0
		invoke WaitForSingleObject,hCloseEvent,INFINITE
		invoke PurgeComm,hCom,PURGE_RXCLEAR		
		invoke CloseHandle,hCom
	.endif
	Ret
_CloseCom EndP

;///////////////////////////////////////////////////////////////////////////////
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam	
	local @hEdit
	local @sendbuff[255]:CHAR
	local @timebuff[255]:CHAR
	mov	eax,wMsg
	.if	eax == WM_CLOSE
		invoke 	EndDialog,hWnd,NULL
	.elseif eax == WM_INITDIALOG
		push hWnd
		pop hWinMain
		call _Init
	.elseif	eax == WM_COMMAND
		mov	eax,wParam
		.if	ax == IDCANCEL || ax == IDM_EXIT
			call _CloseCom
			invoke	EndDialog,hWnd,NULL
		.elseif ax == IDM_ABOUT	;关于
			invoke AboutBox,hWnd,hInstance,hIcon,CTXT("嵌入式实验"),CTXT("串口通信"),\
				CTXT("by crypt0n")
		.elseif ax == IDC_BTN_OPEN ;打开串口
			call _OpenCom
		.elseif ax == IDOK ;发送
			invoke GetDlgItem,hWnd,IDC_EDIT
			mov @hEdit,eax
			invoke GetWindowText,@hEdit,addr @sendbuff,sizeof @sendbuff			
			invoke SendMessage,g_hListBox,LB_ADDSTRING,0,addr @sendbuff
			invoke GetWindowTextLength,@hEdit
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_RED; 红按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "3"
			mov [@sendbuff+3], "r"
			mov [@sendbuff+4], "e"
			mov [@sendbuff+5], "d"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_GREEN; 绿按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "5"
			mov [@sendbuff+3], "g"
			mov [@sendbuff+4], "r"
			mov [@sendbuff+5], "e"
			mov [@sendbuff+6], "e"
			mov [@sendbuff+7], "n"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_BLUE; 蓝按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "4"
			mov [@sendbuff+3], "b"
			mov [@sendbuff+4], "l"
			mov [@sendbuff+5], "u"
			mov [@sendbuff+6], "e"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_WHITE; 白按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "5"
			mov [@sendbuff+3], "w"
			mov [@sendbuff+4], "h"
			mov [@sendbuff+5], "i"
			mov [@sendbuff+6], "t"
			mov [@sendbuff+7], "e"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_YELLOW; 黄按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "6"
			mov [@sendbuff+3], "y"
			mov [@sendbuff+4], "e"
			mov [@sendbuff+5], "l"
			mov [@sendbuff+6], "l"
			mov [@sendbuff+7], "o"
			mov [@sendbuff+8], "w"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_PURPLE; 紫按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "6"
			mov [@sendbuff+3], "p"
			mov [@sendbuff+4], "u"
			mov [@sendbuff+5], "r"
			mov [@sendbuff+6], "p"
			mov [@sendbuff+7], "l"
			mov [@sendbuff+8], "e"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_CYAN; 青按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "4"
			mov [@sendbuff+3], "c"
			mov [@sendbuff+4], "y"
			mov [@sendbuff+5], "a"
			mov [@sendbuff+6], "n"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_DARK; 暗按钮
			mov [@sendbuff+1], "P"; 移动进缓冲区
			mov [@sendbuff+2], "4"
			mov [@sendbuff+3], "d"
			mov [@sendbuff+4], "a"
			mov [@sendbuff+5], "r"
			mov [@sendbuff+6], "k"
			mov eax, sizeof @sendbuff
			invoke _WriteData,addr @sendbuff,eax
		.elseif ax == BUTTON_SYNC_TIME; 同步时间
			invoke	GetLocalTime,addr sysTime
			xor eax,eax
			xor ebx,ebx
			xor ecx,ecx
			mov ax,sysTime.wHour
			mov bx,sysTime.wMinute
			mov cx,sysTime.wSecond
			invoke	wsprintf,addr @timebuff,addr szFromatTime,eax,ebx,ecx
			invoke _WriteData,addr @timebuff,eax
			invoke MessageBox, NULL, addr @timebuff, addr @timebuff, MB_OK
		.endif

	.endif
	xor	eax,eax
	ret
	Ret
_ProcDlgMain EndP

;///////////////////////////////////////////////////////////////////////////////
start:
	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke DialogBoxParam,hInstance,DLG_MAIN,NULL,offset _ProcDlgMain,NULL
	invoke ExitProcess,NULL
;///////////////////////////////////////////////////////////////////////////////
	end start
