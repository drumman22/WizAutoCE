#Requires AutoHotkey v2.0
#SingleInstance Prompt
; Hotkeys and setup for one-handed/mouse-only on Wizard101
; Extra hotkeys for cheat engine can be setup seperately
; by drumman22

w101_exe := "WizardGraphicalClient.exe"
ce_name := "Cheat Engine"
ce_dir := ""

; Just incase: Exit with ctrl+shift+esc
^+F10::ExitApp()

; Press X w/ MButton4
#HotIf WinActive("ahk_exe " w101_exe)
XButton1::SendInput("x")

; Require admin perms
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        if A_IsCompiled {
            Run '*RunAs "' A_ScriptFullPath '" /restart'
		} else {
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
		}
    }
	MsgBox("This AHK script must run with admin permissions.`n`nExiting script..")
    ExitApp()
}

; Attempt to find cheatengine in common locations
Loop Files A_ProgramFiles "*", "D" {
    Loop Files, A_LoopFilePath "\Cheat Engine *", "D" {
		temp_path := A_LoopFilePath
        if FileExist(temp_path "\" ce_name ".exe") {
			ce_dir := temp_path ; only change directory once exe has been found
			break
		} else {
			MsgBox("Your Cheat Engine directory does not contain the correct executable!")
			;ExitApp()
		}
        MsgBox(A_LoopFilePath)
    }
}

; If ce exe was not found then 
if ce_dir {
	; Attempt to find wiz101AutoOpen
	; Used for auto opening wiz101 on cheat engine
	wizAutoOpen_file := ce_dir "\autorun\wiz101AutoOpen.lua"
	if not FileExist(wizAutoOpen_file) {
		result := MsgBox("Would you like to add an auto injector for wizard101 on cheat engine?",, "YesNo")
		if result == "Yes" {
			FileAppend('openProcess("' w101_exe '")', wizAutoOpen_file)
		}
	}
	startTimer()
} else {
	browseGui().Show()
}

; Detects when w101 is open or closed
wizWasActive := false
startTimer() {
	global wizWasActive
	MsgBox("Program started, you may close this")
	SetTimer(DetectWiz, 5000)
	DetectWiz() {
		if ProcessExist(w101_exe) {
			if wizWasActive == false { ; w101 was opened
				if WinWait("ahk_exe " w101_exe) {
					wizWasActive := true
					startCE()
				}
			}
		} else { ; id is 0/none
			if wizWasActive == true { ; w101 was closed
				wizWasActive := false
				stopCE()
			}
		}
	}
}

; When w101 opens
startCE() {
	try {
		Run(ce_dir "\" ce_name ".exe")
		if WinWaitActive(ce_name) {
			WinMinimize(ce_name)
		} else {
			MsgBox("This shouldn't have ran lol")
			ExitApp()
		}
	} catch as e {
		MsgBox("Error: " e.Message "`n`nExiting AHK script!")
		ExitApp()
	}
}

; When w101 closes
stopCE() {
	try {
		if WinExist(ce_name) {
			WinClose(ce_name)
		}
	} catch as e {
		MsgBox("Error: " e.Message "`n`nExiting AHK script!")
		ExitApp()
	}
}

; Gui used for letting the user choose their own path to ce directory
browseGui() {
	MyGui := Gui(, "Cheat Engine not found")
	MyGui.Add("Text",,"Please select the directory where Cheat Engine is installed.`n")
	path := MyGui.Add("Edit", "w250 Disabled", A_ProgramFiles)
	MyGui.Add("Text", "ys", "`n")

	browseBtn := MyGui.Add("Button", "w50", "Browse")
	continueBtn := MyGui.Add("Button", "w50", "Continue")
	browseBtn.OnEvent("Click", onBrowseClick)
	continueBtn.OnEvent("Click", onContinueClick)
	MyGui.OnEvent("Close", onClose)

	onBrowseClick(*) {
		text := DirSelect()
		if text { 
			path.Text := text
		}
	}
	onContinueClick(*) {
		if FileExist(path.Text "\Cheat Engine.exe") {
			ce_dir := path.Text
			MyGui.Destroy()
			return startTimer()
		}
		MsgBox("Cheat Engine is not installed in this Directory!", "Cheat Engine not found")
	}
	onClose(*) {
		ExitApp()
	}

	return MyGui
}