--[[
	----------------------------------------------------------------------------
	App um Notizen zu dem Modellen anzuzeigen und abzuspeichern, in max. 10 Zeilen und 10 Spalten
	----------------------------------------------------------------------------
	
	MIT License

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
   
	Hiermit wird unentgeltlich jeder Person, die eine Kopie der Software und der
	zugehörigen Dokumentationen (die "Software") erhält, die Erlaubnis erteilt,
	sie uneingeschränkt zu nutzen, inklusive und ohne Ausnahme mit dem Recht, sie
	zu verwenden, zu kopieren, zu verändern, zusammenzufügen, zu veröffentlichen,
	zu verbreiten, zu unterlizenzieren und/oder zu verkaufen, und Personen, denen
	diese Software überlassen wird, diese Rechte zu verschaffen, unter den
	folgenden Bedingungen: 
	Der obige Urheberrechtsvermerk und dieser Erlaubnisvermerk sind in allen Kopien
	oder Teilkopien der Software beizulegen. 
	DIE SOFTWARE WIRD OHNE JEDE AUSDRÜCKLICHE ODER IMPLIZIERTE GARANTIE BEREITGESTELLT,
	EINSCHLIEßLICH DER GARANTIE ZUR BENUTZUNG FÜR DEN VORGESEHENEN ODER EINEM
	BESTIMMTEN ZWECK SOWIE JEGLICHER RECHTSVERLETZUNG, JEDOCH NICHT DARAUF BESCHRÄNKT.
	IN KEINEM FALL SIND DIE AUTOREN ODER COPYRIGHTINHABER FÜR JEGLICHEN SCHADEN ODER
	SONSTIGE ANSPRÜCHE HAFTBAR ZU MACHEN, OB INFOLGE DER ERFÜLLUNG EINES VERTRAGES,
	EINES DELIKTES ODER ANDERS IM ZUSAMMENHANG MIT DER SOFTWARE ODER SONSTIGER
	VERWENDUNG DER SOFTWARE ENTSTANDEN. 
	
	Ursprüngliche Idee und Programmierung von Thorsten Tiedge 
	
	Version 1.2: Aufteilung der Eingabefelder auf mehrere Spalten und Anpassung der Spaltenbreite auf das breiteste Feld
	Version 1.3: Speichern und Laden vereinfacht
	Version 1.4: MIT Lizenz ergänzt, Speicherordner von "Apps/Modelle/" auf "Apps/Notizbuch/" geändert.
	Version 1.5: Zur besseren Les- und Editierbarkeit mittels Texteditor werden die Daten und Einstellungen nun als JSN Datei abgespeichert.
				 Dies geschieht nun automatisch nach jeder Änderung der Daten oder Einstellungen, und der Dateiname wird wie folgt vergeben: Modellname_NB-appNumber.JSN
				 Die appNumber kann untenstehend geändert werden und muss dem Dateinamen der App entsprechen, z.Bsp: bei Notizbuch7.lua muss die appNumber = 7 sein.
				 Es können sowohl die neuen JSN Dateien als auch die alten txt Dateien geladen werden.
	Version 1.6: Die Sicherungsdateien werden sofort nach Import einer txt Datei erstellt.
	Version 1.7: Zeilenhöhe gleichmäßig aufgeteilt und zentriert
	Version 1.8: Bei Änderung der Zeilen- und Spaltenanzahl bleiben die Werte erhalten werden aber nicht angezeigt um ein unabsichtliches Löschen zu vermeiden.
	Version 2.0: Umbenannt in Notebook und komplett überarbeitet
	
	https://github.com/ribid1/Notizbuch

--]]--------------------------------------------------------------------------------

--[[one
-- nach unbeabsichtigten globalen Variablen suchen
setmetatable(_G, {
	__newindex = function(array, key, value)
		print(string.format("Changed _G: %s = %s", tostring(key), tostring(value)));
		rawset(array, key, value);
	end
});
--]]
local app = "Notebook"
local appNumber = "2"     -- Hier die Nummer antsprechend des Dateinamens abändern
local frameForms = {}
local model, pages, formID
local config = ""
local change = false
local height = {}
local startX = {}
local startY = {}
local yText = {}
local frame = {}
local font = {}
local width = {}
local borderX  = 2
local borderY  = -0.5
local cd = {}
cd.conf = {}
cd.texts = {}
local windows = 2
local fontOptions = {"Mini", "Normal", "Bold", "Maxi"}
local fontConstants = {FONT_MINI, FONT_NORMAL, FONT_BOLD, FONT_MAXI}
local alignForms = {}
local defaultNumber = 0
local defaultText = ""
local seitlich = false
local sel = 1
local tempsel = 1
local templine
local trans
local version = "2.0"

local function loadoldJsonConfig(filename)
	local i,j,k,l
	local temp	
	local conf = {}
	local file = io.open("Apps/"..app.."/"..filename, "r")
	if (file) then
		for i,j in ipairs(cd.texts) do
			conf = json.decode(io.readline(file,true))	
			cd.conf[i].align = {}
			cd.conf[i].font = conf.fonts
			cd.conf[i].frame = conf.frames
			cd.conf[i].inputColumns = conf.inputColumns
			temp = io.readline(file,true)
			k = 0
			while temp ~= "---" do
				k = k + 1
				j[k] = json.decode(temp)
				temp = io.readline(file,true)			
			end
			if conf.rows then
				for l = k, #j do j[l] = nil end
			end
		end
		io.close(file)
	end
end

local function loadJsonConfig(filename)
	local file = io.readall("Apps/"..app.."/"..filename, "r")
	if (file) then
		cd = json.decode(file)
	end
end

local function saveJsonConfig()
	local file = io.open("Apps/"..app.."/"..model.."_NB"..appNumber..".jsn", "w+")
	if (file) then
		io.write(file, json.encode(cd))
		io.close(file)
	end
end

local function loadConfig()
	if (config:len() > 4) then
		if string.upper(string.sub(config,-6,-6)) == "-" then
			loadoldJsonConfig(config)
		else
			loadJsonConfig(config)
		end
		change = true
	end 
end

local function calcPage(w)
	width[w] = {}
	font[w] = fontConstants[cd.conf[w].font]
	if cd.conf[w].frame then
		frame[w] = 1
	else
		frame[w] = 0
	end	
	local heightmin  = lcd.getTextHeight(font[w], "|Kp") + frame[w] + borderY * 2
	local heightmax  = heightmin * 2
	local rows = #cd.texts[w]
	startY[w] = 0
	height[w] = math.floor((cd.Height + borderY*2 - frame[w] - frame[w]*borderY*2)/rows)
	-- print("rows:"..rows)
	-- print("heightmin:"..heightmin)
	-- print("heightmax:"..heightmax)
	-- print("height:"..height[w])
	if height[w] < heightmin then
		height[w] = heightmin
	elseif height[w] > heightmax then 
		height[w] = heightmax 
	end
	startY[w]  = math.floor(((cd.Height) - height[w] * rows - frame[w])/2)
	-- print("starty:"..startY[w])
	yText[w] = startY[w] + math.floor((height[w]-heightmin)/2)
	
	for i = 1, #cd.texts[w][1] do
		width[w][i]=10
	end
	for i,r in pairs(cd.texts[w]) do
		for j,s in ipairs(r) do
			if width[w][j] < lcd.getTextWidth(font[w],s) + borderX*2 + frame[w] then
				width[w][j] = lcd.getTextWidth(font[w],s) + borderX*2 + frame[w]
			end
		end
	end
	local gesbreite = frame[w] + frame[w]*borderX*2 - borderX*2
	for i,j in ipairs(width[w]) do
		gesbreite = gesbreite + j
	end
	startX[w] = (cd.Width-gesbreite)/2
end

local function showPage(w)
	local i,j,breite,r
	local temp
	local y
	local x = startX[w] + frame[w] + frame[w]*borderX
	for i,breite in ipairs(width[w]) do
		y = yText[w]
		if cd.conf[w].align[i] then
			temp = x + breite - borderX * 2 - frame[w]
			for j,r in pairs(cd.texts[w]) do
				lcd.drawText(temp - lcd.getTextWidth(font[w], r[i]), y, r[i], font[w])
				y = y + height[w]
			end
		else
			for j,r in pairs(cd.texts[w]) do
				if tonumber(r[i]) then
					lcd.drawText(x + breite - lcd.getTextWidth(font[w], r[i]) - borderX*2 - frame[w], y, r[i], font[w])
				else
					lcd.drawText(x, y, r[i], font[w])
				end
				y = y + height[w]
			end
		end
		x = x + breite
	end
	x = x - borderX - 1
	if cd.conf[w].frame then
		y = startY[w]
		lcd.drawLine(startX[w], y, x, y)
		for i = 1,#cd.texts[w] do --horizontal
			y = y + height[w]
			lcd.drawLine(startX[w], y, x, y)
		end
		x = startX[w]
		lcd.drawLine(x, startY[w], x, y)
		for i,breite in ipairs(width[w]) do  --vertikal
			x = x + breite
			lcd.drawLine(x, startY[w], x, y)
		end
	end
end

local function showPage1(width, height)
	cd.Width = width+1 
	cd.Height = height+1
	return showPage(1)
end

local function showPage2(width, height)
	cd.Width = width+1 
	cd.Height = height+1
	return showPage(2)
end

local function setupForm1()
	local iSpalten
	for w=1, windows do
		form.addRow(1)
		form.addLabel({label = trans.Fenster..w, font=FONT_BOLD})

		form.addRow(2)
		form.addLabel({label = trans.Zeilen, width=200})
		form.addIntbox(#cd.texts[w], 1, 14, 2, 0, 1, function(value)
			if (#cd.texts[w] < value) then
				for i=#cd.texts[w]+1, value do
					if not cd.texts[w][i] then 
						cd.texts[w][i] = {}
						for j=1, #cd.texts[w][1] do
							cd.texts[w][i][j] = defaultText
			 			end
					end
				end
			else
				for i= value+1, #cd.texts[w] do
					cd.texts[w][i]=nil
				end
			end
			change = true
		end)

		form.addRow(2)
		form.addLabel({label = trans.Spalten, width=200})
		form.addIntbox(#cd.texts[w][1], 1, 10, 2, 0, 1, function(value)
			iSpalten=#cd.texts[w][1]
			for i=1, #cd.texts[w] do
				if iSpalten < value then
					for j=iSpalten + 1, value do
						if not cd.texts[w][i][j] then 
							cd.texts[w][i][j] = defaultText 
						end
					end
				else
					for j=value+1, iSpalten do
						cd.texts[w][i][j] = nil
					end
				end
			end
			if value < cd.conf[w].inputColumns then  
				cd.conf[w].inputColumns = value
			end
			change = true
		end)
		
		form.addRow(2)
		form.addLabel({label = trans.Eingabespalten, width=200})
		
		form.addIntbox(cd.conf[w].inputColumns,1,6,1,0,1, function(value)
			if value > #cd.texts[w][1] then  value = #cd.texts[w][1] end
			cd.conf[w].inputColumns = value
			change = true
		end)
		
		form.addRow(2)
		form.addLabel({label = trans.Schrift, width=200})
		form.addSelectbox(fontOptions, cd.conf[w].font, false, function(value)
			cd.conf[w].font = value
			change = true
		end)

		form.addRow(2)
		form.addLabel({label = trans.Rahmen, width=275})
		frameForms[w] = form.addCheckbox(cd.conf[w].frame, function(value)
			 cd.conf[w].frame = not value
			 form.setValue(frameForms[w], not value)
			 change = true
		end)

		form.addSpacer(1, 7)
	end

	form.addRow(1)
	form.addLabel({label = trans.loadConfig, font=FONT_BOLD})
	local dateinamen = {}
	dateinamen[1]=""
	for name, filetype, size in dir("Apps/"..app) do
		if filetype == "file" then table.insert(dateinamen, name) end
	end
	table.sort(dateinamen)
	form.addRow(2)
	form.addLabel({label = trans.Name, width=100})
	form.addSelectbox(dateinamen,1,false, function(value)
		config = dateinamen[value]
		form.setButton(4, "Load", config:len() > 4 and ENABLED or DISABLED)
	end, {width = 210})
	form.addSpacer(1, 7)
	form.addRow(1)
	form.addLabel({label=trans.ZahltoText, font=FONT_MINI, alignRight=false, enabled=false})
	form.addRow(1)
	form.addLabel({label=trans.laden, font=FONT_MINI, alignRight=false, enabled=false})
	form.addSpacer(1, 7)
	form.addRow(1)
	form.addLabel({label=trans.changedir1, font=FONT_MINI, alignRight=false, enabled=false})
	form.addRow(1)
	form.addLabel({label=trans.changedir2, font=FONT_MINI, alignRight=false, enabled=false})
	form.addSpacer(1, 7)
	form.addRow(1)
	form.addLabel({label="Designed by dit71 - v."..version, font=FONT_MINI, alignRight=false, enabled=false})
end

local function setupFormTable(w)
    calcPage(w)
	local stellen
	local fontEingabe = FONT_NORMAL
	local number
	local isText
	local i, j, k, r, m, n, p
	local gesBreite
	local maxBreite = {}
	local sortmaxBreite = {}
	local key
	local temp
	local BSchirm
	local alignForms = {}
	local minBreite = 40 + 5 * (7-cd.conf[w].inputColumns)
	local selcol = {}
	for i = 1,#width[w] do	
		selcol[i] = tostring(i)
	end
	form.addRow(2)
	form.addLabel({label = trans.movecolumn, font=FONT_NORMAL, alignRight=true, width=160, enabled=false})
	form.addSelectbox(selcol, sel, false, function(value)
						sel = value
						tempsel = sel
					end,{width=40})
	n = 0
	for i = 1, math.ceil(#width[w]/cd.conf[w].inputColumns) do
		m = n + 1
		n = m + cd.conf[w].inputColumns - 1
		if n > #width[w] then n = #width[w] end
		gesBreite = 0
		for p,_ in pairs(maxBreite) do maxBreite[p] = nil end
		for p,_ in pairs(sortmaxBreite) do sortmaxBreite[p] = nil end
		for k = m,n do
			maxBreite[k] = width[w][k] - frame[w] - borderX * 2
			gesBreite = gesBreite + maxBreite[k]
		end	
		--for k,m in pairs(maxBreite) do print(k.."-"..m) end
		--print("dd")
		
		for key in pairs(maxBreite) do
			table.insert(sortmaxBreite, key)
		end		
	
		table.sort(sortmaxBreite, function(a,b)
			return maxBreite[a] < maxBreite[b] end)
				
		--for k,m in ipairs(sortmaxBreite) do print(k.."-"..m) end
		
		BSchirm = cd.Width - 33
		for  _,key in pairs(sortmaxBreite) do
			temp = maxBreite[key]
			maxBreite[key] = maxBreite[key]/gesBreite * BSchirm
			if maxBreite[key] < minBreite then maxBreite[key] = minBreite end
			gesBreite = gesBreite - temp
			BSchirm = BSchirm - maxBreite[key]
		end
		form.addRow(n + 2) --max.8, darum max. 6 Eingabespalten (6+2=8)
		form.addLabel({label = "S:", font=FONT_NORMAL,alignRight=true,width=28, enabled=false})
		form.addSpacer(14,1)
		maxBreite[m-1] = 0
		for k = m,n do
			form.addLabel({label = math.ceil(k), font=FONT_NORMAL,alignRight=true,width = maxBreite[k]/2 + maxBreite[k-1]/2, enabled=false})
		end
		form.addRow(n + 1)
		form.addLabel({label = "R:", font=FONT_NORMAL,alignRight=true, width=28, enabled=false})
		for k = m,n do
			alignForms[k] = form.addCheckbox(cd.conf[w].align[k], function(value)
				 cd.conf[w].align[k] = not value
				 form.setValue(alignForms[k], not value)
				 change = true
			end,{width = maxBreite[k]})
		end
		
		for j,r in ipairs(cd.texts[w]) do
			form.addRow(n + 1)
			form.addLabel({label = j..":", font=FONT_NORMAL,alignRight=true,width=28, enabled=false})
			for k = m,n do
				isText = true
				number = tonumber(r[k])
				if number then
					stellen = r[k]:len()-((string.find(r[k],".",1,true)) or r[k]:len())
					number=number*10^stellen
					if number > -10000 and number < 10000 then
						isText = false
						form.addIntbox(number, -10000, 9999, 0,stellen, 1, function(value)
							value  = tostring(string.format("%."..stellen.."f",value/10^stellen))
							r[k] = value
							change = true
						end, {font=fontEingabe, width = maxBreite[k]})
					end
				end
				if isText then
					form.addTextbox(r[k], 40, function(value)
						r[k] = value
						change = true
					end,{font=fontEingabe, width = maxBreite[k]})
				end 
			end
		end
		form.addRow(1)
		form.addSpacer(cd.Width,15)
	end
end

local function setupForm(id)
	formID = id

	if (formID == 1) then
		setupForm1()
	elseif (formID == 2) then
		setupFormTable(1)
	elseif (formID == 3) then
		setupFormTable(2)
	end

	form.setButton(1, "O", formID == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "1", formID == 2 and HIGHLIGHTED or ENABLED)
	form.setButton(3, "2", formID == 3 and HIGHLIGHTED or ENABLED)

	if (formID == 1) then
		form.setButton(4, "Load", HIGHLIGHTED or config:len() > 4 and ENABLED or DISABLED)
	elseif seitlich then
		form.setButton(4, ":left", ENABLED)
		form.setButton(5, ":right", ENABLED)
	else
		form.setButton(4, ":up", ENABLED)
		form.setButton(5, ":down", ENABLED)
	end
end

local function getFocusedEntry(w, rows, line)
	local line    = form.getFocusedRow()
	local row     = line - 3 - (rows + 3) * (math.ceil((line-1)/(rows + 3))-1)
	local column  = 1 + cd.conf[w].inputColumns * (math.ceil((line-1)/(rows + 3))-1)
	-- print("line:"..line)
	-- print("row:"..row)
	-- print("col:"..column)
	return row, column, line
end

local function setFocusedEntry(w, row, column)
	local columns = #width[w]
	local line    = (row - 1) * (columns + 2) + (column > 0 and column + 1 or 0)
	form.setFocusedRow(line)
end

local function getNextIndex(size, index, back)
	return (back and index - 2 or index) % size + 1
end

local function moveLine(w, back)
	local rows        = #cd.texts[w]
	local columns     = #width[w]
	local row, column, line = getFocusedEntry(w, rows)
	local index
	local to
	if row > 0 then
		if seitlich then
			if line ~= templine then tempsel = sel end
			index = getNextIndex(columns, tempsel, back)
			cd.texts[w][row][index], cd.texts[w][row][tempsel] = cd.texts[w][row][tempsel], cd.texts[w][row][index]
			tempsel = index
			line = 3 + row + (rows + 3) * (math.ceil(index / cd.conf[w].inputColumns) - 1)
			templine = line
			form.setFocusedRow(line)
		else
			index = getNextIndex(rows, row, back)
			to = column + cd.conf[w].inputColumns - 1
			for i = column, to < columns and to or columns do
				cd.texts[w][index][i], cd.texts[w][row][i] = cd.texts[w][row][i], cd.texts[w][index][i]
			end
			line = line - row + (back and row - 2 or row) % rows + 1
			form.setFocusedRow(line)
		end
	end
	change = true
end

local function keyForm(key)
	if (key == KEY_1 and formID ~= 1) then
		form.reinit(1)
	elseif key == KEY_2 then 
		if formID ~= 2 then
			form.reinit(2)
		else
			seitlich = not seitlich
			form.reinit(2)
		end		
	elseif key == KEY_3 then 
		if formID ~= 3 then
			form.reinit(3)
		else
			seitlich = not seitlich
			form.reinit(3)
		end		
	elseif (key == KEY_4) then
		if (formID == 1) then
			loadConfig()
		else
			moveLine(formID - 1, true)
		end
		form.reinit(formID)
	elseif (key == KEY_5) then
		if not (formID == 1) then
			form.preventDefault()
			moveLine(formID - 1)
		end
		form.reinit(formID)
	end
end

local function loop()
	if change and not form.getActiveForm() then
		calcPage(1)
		calcPage(2)
		saveJsonConfig()
		change = false
	end
end

local function init()
	pages = {showPage1, showPage2}
	model = system.getProperty("Model") or ""
	cd.texts[1] = {}
	cd.texts[2] = {}
	cd.conf[1] = {}
	cd.conf[2] = {}
	
	local file
	local lng = system.getLocale()
	local j
	file = io.readall("Apps/"..app.."/NB_lang.jsn")
	local obj = json.decode(file)
	if obj then
		trans = obj[lng] or obj[obj.default]
	end

	local file = io.readall("Apps/"..app.."/"..model.."_NB"..appNumber..".jsn", "r")
	if file then
		cd = json.decode(file)
	else
		for w=1, windows do
			for i=1, 2 do
				cd.texts[w][i]= {}
				for j=1, 2 do
						cd.texts[w][i][j] = defaultText
				end
			end
			cd.conf[w].inputColumns = 1
			cd.conf[w].font = 1
			cd.conf[w].frame = 1
			cd.conf[w].align = {}
		end
		cd.Width = 320 
		cd.Height = 160
	end
	calcPage(1)
	calcPage(2)
	local r,g,b   = lcd.getBgColor()
	if (r+g+b)/3 > 128 then
	    r,g,b = 0,0,0
	else
	    r,g,b = 255,255,255
	end
	lcd.setColor(r,g,b)

	system.registerForm(1, MENU_MAIN, app.." "..appNumber, setupForm, keyForm)
	for w=1, windows do
		system.registerTelemetry(w, app.." "..appNumber..w.." - "..model, 4, pages[w])   -- full size Window
	end
end

return {init=init, loop=loop, author="dit71", version=version, name = app.." "..appNumber}