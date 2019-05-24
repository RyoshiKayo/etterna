-- shamelessly adapted from spawncamping-wallhack
local top
local profile = PROFILEMAN:GetProfile(PLAYER_1)

local curType = 1
local assetTypes = {}
for k,v in pairs(assetFolders) do
    assetTypes[curType] = k
    curType = curType + 1
end
curType = 1

local maxPage = 1
local curPage = 1
local maxRows = 5
local maxColumns = 5
local curIndex = 1
local GUID = profile:GetGUID()
local curPath = ""

local assetTable = {}

local frameWidth = SCREEN_WIDTH - 20
local frameHeight = SCREEN_HEIGHT - 40
local assetWidth = 50
local assetHeight = 50
local assetXSpacing = (frameWidth - 20) / (maxColumns + 1)
local assetYSpacing = (frameHeight - 20) / (maxRows + 1)

local co -- for async loading images

local function isImage(filename)
	local extensions = {".png", ".jpg", "jpeg"} -- lazy list
	local ext = string.sub(filename, #filename-3)
	for i=1, #extensions do
		if extensions[i] == ext then return true end
	end
	return false
end

local function isAudio(filename)
	local extensions = {".wav", ".mp3", ".ogg", ".mp4"} -- lazy to check and put in names
	local ext = string.sub(filename, #filename-3)
	for i=1, #extensions do
		if extensions[i] == ext then return true end
	end
	return false
end

local function loadAssetTable() -- load asset table for current type
	local type = assetTypes[curType]
	assetTable = filter(isImage, FILEMAN:GetDirListing(assetFolders[type]))
end


local function updateImages() -- Update all image actors (sprites)
	loadAssetTable()
    for i=1, math.min(maxRows * maxColumns, #assetTable) do
        MESSAGEMAN:Broadcast("UpdateAsset", {index = i})
        coroutine.yield()
    end
	MESSAGEMAN:Broadcast("UpdateFinished")
end

local function toggleAssetType(n) -- move asset type forward/backward
    if n > 0 then n = 1 else n = -1 end
    curType = curType + n
    if curType > #assetTypes then
        curType = 1
    elseif curType == 0 then
        curType = #assetTypes
    end
end

local function getIndex() -- Get cursor index
    return ((curPage-1) * maxColumns * maxRows) + curIndex
end

local function movePage(n) -- Move n pages forward/backward
    local nextPage = curPage + n
    if nextPage > maxPage then
        nextPage = maxPage
    elseif nextPage < 1 then
        nextPage = 1
    end

    -- This loads all images again if we actually move to a new page.
    if nextPage ~= curPage then
        curIndex = n < 0 and math.min(#assetTable, maxRows * maxColumns) or 1
        curPage = nextPage
        MESSAGEMAN:Broadcast("PageMoved",{index = curIndex, page = curPage})
        co = coroutine.create(updateImages)
    end
end

local function moveCursor(x, y) -- move the cursor i dunno
    local move = x + y * maxColumns
    local nextPage = curPage

    if curPage > 1 and curIndex == 1 and move < 0 then
        curIndex = math.min(#assetTable, maxRows * maxColumns)
        nextPage = curPage - 1
    elseif curPage < maxPage and curIndex == maxRows * maxColumns and move > 0 then
        curIndex = 1
        nextPage = curPage + 1
    else
        curIndex = curIndex + move
        if curIndex < 1 then
            curIndex = 1
        elseif curIndex > math.min(maxRows * maxColumns, #assetTable - (maxRows * maxColumns * (curPage-1))) then
            curIndex = math.min(maxRows * maxColumns, #assetTable - (maxRows * maxColumns * (curPage-1)))
        end
	end
	if curPage == nextPage then
		MESSAGEMAN:Broadcast("CursorMoved",{index = curIndex})
	else
		curPage = nextPage
		MESSAGEMAN:Broadcast("PageMoved",{index = curIndex, page = curPage})
		co = coroutine.create(updateImages)

	end
end

local function assetBox(i)
    local name = assetTable[i]
    local t = Def.ActorFrame {
        Name = tostring(i),
        InitCommand = function(self)
            self:x((((i-1) % maxColumns)+1)*assetXSpacing)
            self:y(((math.floor((i-1)/maxColumns)+1)*assetYSpacing)-10+50)
            self:diffusealpha(0)
        end,
        PageMovedMessageCommand = function(self)
			self:finishtweening()
			self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
			self:diffusealpha(0)
        end,
        UpdateAssetMessageCommand = function(self, params)
			if params.index == i then
				if i+((curPage-1)*maxColumns*maxRows) > #assetTable then
					self:finishtweening()
					self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
					self:diffusealpha(0)
				else
					name = assetTable[i+((curPage-1)*maxColumns*maxRows)]

					-- Load the asset image
					self:GetChild("Image"):playcommand("LoadAsset")
					if i == curIndex then
						self:GetChild("Image"):zoomto(assetHeight+8,assetWidth+8)
						self:GetChild("Border"):zoomto(assetHeight+12,assetWidth+12)
						self:GetChild("Border"):diffuse(getMainColor("highlight")):diffusealpha(0.8)
					else
						self:GetChild("Image"):zoomto(assetHeight,assetWidth)
					end

					self:y(((math.floor((i-1)/maxColumns)+1)*assetYSpacing)-10+50)
					self:finishtweening()
					self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
					self:diffusealpha(1)
					self:y((math.floor((i-1)/maxColumns)+1)*assetYSpacing+50)
							
				end
            end
		end,
		UpdateFinishedMessageCommand = function(self)
			if assetTable[i+((curPage-1)*maxColumns*maxRows)] == nil then
				self:finishtweening()
				self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
				self:diffusealpha(0)
			end
		end
    }

    t[#t+1] = Def.Quad {
        Name = "Border",
        InitCommand = function(self)
            self:zoomto(assetWidth+4, assetHeight+4)
            self:queuecommand("Set")
            if name == curPath then
                curIndex = i
            end
            self:diffuse(getMainColor("positive")):diffusealpha(0.8)
        end,
        CursorMovedMessageCommand = function(self, params)
			self:finishtweening()
			if params.index == i then
				self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
				self:zoomto(assetWidth+12, assetHeight+12)
				self:diffuse(getMainColor("highlight")):diffusealpha(0.8)
			else
				self:smooth(0.2)
				self:zoomto(assetWidth+4, assetHeight+4)
				self:diffuse(getMainColor("positive")):diffusealpha(0.8)
			end
		end,
		PageMovedMessageCommand = function(self, params)
			self:finishtweening()
			if params.index == i then
				self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
				self:zoomto(assetWidth+12, assetHeight+12)
				self:diffuse(getMainColor("highlight")):diffusealpha(0.8)
			else
				self:smooth(0.2)
				self:zoomto(assetWidth+4, assetHeight+4)
				self:diffuse(getMainColor("positive")):diffusealpha(0.8)
			end
		end
    }

    --[[
    t[#t+1] = quadButton(3) .. {
		InitCommand = function(self)
			self:zoomto(avatarWidth, avatarHeight)
			self:visible(false)
		end,
		TopPressedCommand = function(self, params)
			-- Move the cursor to this index upon clicking
			if params.input == "DeviceButton_left mouse button" then
				-- Save and exit upon double clicking
				if lastClickedIndex == i then
					avatarConfig:get_data().avatar[GUID] = avatarTable[getAvatarIndex()]
					avatarConfig:set_dirty()
					avatarConfig:save()
					SCREENMAN:GetTopScreen():Cancel()
					MESSAGEMAN:Broadcast("AvatarChanged")
				end

				lastClickedIndex = i
				curIndex = i
				MESSAGEMAN:Broadcast("CursorMoved",{index = i})
			end
		end
    }]]
    
    t[#t+1] = Def.Sprite {
        Name = "Image",
        LoadAssetCommand = function(self)
            local type = assetTypes[curType]
            local path = assetFolders[type] .. name
			self:LoadBackground(path)
        end,
		CursorMovedMessageCommand = function(self, params)
			self:finishtweening()
			if params.index == i then
				self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
				self:zoomto(assetWidth+8, assetHeight+8)
			else
				self:smooth(0.2)
				self:zoomto(assetWidth, assetHeight)
			end
		end,
		PageMovedMessageCommand = function(self, params)
			self:finishtweening()
			if params.index == i then
				self:tween(0.5,"TweenType_Bezier",{0,0,0,0.5,0,1,1,1})
				self:zoomto(assetWidth+8, assetHeight+8)
			else
				self:smooth(0.2)
				self:zoomto(assetWidth, assetHeight)
			end
		end
    }
    
    return t
end

local function highlight(self)
	self:queuecommand("Highlight")
end

local function mainContainer()
	local fontScale = 0.5
	local smallFontScale = 0.35
	local fontRow1 = -frameHeight/2+20
	local fontRow2 = -frameHeight/2+40
	local fontSpacing = 15
	local at

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:SetUpdateFunction(highlight)
		end
	}

    t[#t+1] = Def.Quad {
        InitCommand = function(self)
            self:zoomto(frameWidth, frameHeight)
            self:diffuse(color("#333333")):diffusealpha(0.8)
        end
	}
	
	t[#t+1] = LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:zoom(fontScale)
			self:halign(0)
			self:xy(-frameWidth/2 + fontSpacing, fontRow1)
			self:settext("Asset Settings")
		end
	}

	t[#t+1] = LoadFont("Common Large") .. {
		Name = "AssetType",
		InitCommand = function(self)
			self:zoom(fontScale)
			self:xy(50, fontRow1)
			self:queuecommand("Set")
			at = self
		end,
		SetCommand = function(self)
			local type = assetTypes[curType]
			self:settext(type:gsub("^%l", string.upper))
		end
	}

	t[#t+1] = LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:zoom(smallFontScale)
			self:xy(-50, fontRow1)
			self:settext("Prev")
		end,
		HighlightCommand = function(self)
			if isOver(self) then
				self:diffusealpha(1)
			else
				self:diffusealpha(0.6)
			end
		end,
		MouseLeftClickMessageCommand = function(self)
			if isOver(self) then
				toggleAssetType(-1)
				at:playcommand("Set")
				co = coroutine.create(updateImages)
			end
		end
	}

	t[#t+1] = LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:zoom(smallFontScale)
			self:xy(150, fontRow1)
			self:settext("Next")
		end,
		HighlightCommand = function(self)
			if isOver(self) then
				self:diffusealpha(1)
			else
				self:diffusealpha(0.6)
			end
		end,
		MouseLeftClickMessageCommand = function(self)
			if isOver(self) then
				toggleAssetType(1)
				at:playcommand("Set")
				co = coroutine.create(updateImages)
			end
		end
	}

    return t
end


local function input(event)
	if event.type ~= "InputEventType_Release" then
		-- Screen exits upon first press anyway so no need to check for repeats.
		if event.button == "Back" then
			SCREENMAN:GetTopScreen():Cancel()
		end

		if event.button == "Start" then
			--avatarConfig:get_data().avatar[GUID] = avatarTable[getAvatarIndex()]
			--avatarConfig:set_dirty()
			--avatarConfig:save()
			SCREENMAN:GetTopScreen():Cancel()
			--MESSAGEMAN:Broadcast("AvatarChanged")
		end

		-- We want repeats for these events anyway
		if event.button == "Left" or event.button == "MenuLeft" then
			moveCursor(-1, 0)
		end

		if event.button == "Right" or event.button == "MenuRight" then
			moveCursor(1, 0)
		end

		if event.button == "Up" or event.button == "MenuUp" then
			moveCursor(0, -1)
		end

		if event.button == "Down" or event.button == "MenuDown" then
			moveCursor(0, 1)
		end

		if event.button == "EffectUp" then
			movePage(-1)
		end

		if event.button == "EffectDown" then
            movePage(1)
        end
	end
	if event.type == "InputEventType_FirstPress" then
		if event.DeviceInput.button == "DeviceButton_left mouse button" then
			MESSAGEMAN:Broadcast("MouseLeftClick")
		elseif event.DeviceInput.button == "DeviceButton_right mouse button" then
			MESSAGEMAN:Broadcast("MouseRightClick")
		end
	end

	return false

end

local function update(self, delta)
	if coroutine.status(co) ~= "dead" then
		coroutine.resume(co)
	end
end

local t = Def.ActorFrame {
    InitCommand = function(self)

    end,
	BeginCommand = function(self)
        top = SCREENMAN:GetTopScreen()
        top:AddInputCallback(input)
        co = coroutine.create(updateImages)
        self:SetUpdateFunction(update)
    end
}

t[#t+1] = mainContainer() .. {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    end
}

for i=1, maxRows * maxColumns do
    t[#t+1] = assetBox(i)
end

return t