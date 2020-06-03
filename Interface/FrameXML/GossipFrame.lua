GossipTitleButtonMixin = {}

function GossipTitleButtonMixin:OnHide()
	self:CancelCallback();
	self.ClearData();
end

function GossipTitleButtonMixin:CancelCallback()
	if self.cancelCallback then
		self.cancelCallback();
		self.cancelCallback = nil;
	end
end

function GossipTitleButtonMixin:AddCallbackForQuest(questID, cb)
	self:CancelCallback();
	self.cancelCallback = QuestEventListener:AddCancelableCallback(questID, cb);
end

function GossipTitleButtonMixin:SetQuest(titleText, level, isTrivial, frequency, isRepeatable, isLegendary, isIgnored, questID)
	self.type = "Available";

	QuestUtil.ApplyQuestIconOfferToTexture(self.Icon, isLegendary, frequency, isRepeatable, C_CampaignInfo.IsCampaignQuest(questID), C_QuestLog.IsQuestCalling(questID))
	self:UpdateTitleForQuest(questID, titleText, isIgnored, isTrivial);
end

function GossipTitleButtonMixin:SetActiveQuest(titleText, level, isTrivial, isComplete, isLegendary, isIgnored, questID)
	self.type = "Active";

	QuestUtil.ApplyQuestIconActiveToTexture(self.Icon, isComplete, isLegendary, nil, nil, C_CampaignInfo.IsCampaignQuest(questID), C_QuestLog.IsQuestCalling(questID));
	self:UpdateTitleForQuest(questID, titleText, isIgnored, isTrivial);
end

function GossipTitleButtonMixin:SetOption(titleText, iconName)
	self.type = "Gossip";

	self:SetText(titleText);
	self.Icon:SetTexture("Interface/GossipFrame/" .. iconName .. "GossipIcon");
	self.Icon:SetVertexColor(1, 1, 1, 1);

	self:Resize();
end

function GossipTitleButtonMixin:UpdateTitleForQuest(questID, titleText, isIgnored, isTrivial)
	if ( isIgnored ) then
		self:SetFormattedText(IGNORED_QUEST_DISPLAY, titleText);
		self.Icon:SetVertexColor(0.5,0.5,0.5);
	elseif ( isTrivial ) then
		self:SetFormattedText(TRIVIAL_QUEST_DISPLAY, titleText);
		self.Icon:SetVertexColor(0.5,0.5,0.5);
	else
		self:SetFormattedText(NORMAL_QUEST_DISPLAY, titleText);
		self.Icon:SetVertexColor(1,1,1);
	end

	self:Resize();
end

function GossipTitleButtonMixin:Resize()
	self:SetHeight(math.max(self:GetTextHeight() + 2, self.Icon:GetHeight()));
end

function GossipFrame_OnLoad(self)
	self:RegisterEvent("GOSSIP_SHOW");
	self:RegisterEvent("GOSSIP_CLOSED");
	self:RegisterEvent("QUEST_LOG_UPDATE");

	self.titleButtonPool = CreateFramePool("Button", self, "GossipTitleButtonTemplate");
end

function GossipFrame_OnEvent(self, event, ...)
	if ( event == "GOSSIP_SHOW" ) then
		-- if there is only a non-gossip option, then go to it directly
		if ( (GetNumGossipAvailableQuests() == 0) and (GetNumGossipActiveQuests() == 0) and (GetNumGossipOptions() == 1) and not ForceGossip() ) then
			local text, gossipType = GetGossipOptions();
			if ( gossipType ~= "gossip" ) then
				SelectGossipOption(1);
				return;
			end
		end

		if ( not GossipFrame:IsShown() ) then
			ShowUIPanel(self);
			if ( not self:IsShown() ) then
				CloseGossip();
				return;
			end
		end
		NPCFriendshipStatusBar_Update(self);
		GossipFrameUpdate();
	elseif ( event == "GOSSIP_CLOSED" ) then
		HideUIPanel(self);
	elseif ( event == "QUEST_LOG_UPDATE" and GossipFrame.hasActiveQuests ) then
		GossipFrameUpdate();
	end
end

function GossipFrameUpdate()
	GossipFrame.titleButtonPool:ReleaseAll();
	GossipFrame.buttons = {};

	GossipGreetingText:SetText(GetGossipText());
	GossipFrameAvailableQuestsUpdate(GetGossipAvailableQuests());
	GossipFrameActiveQuestsUpdate(GetGossipActiveQuests());
	GossipFrameOptionsUpdate(GetGossipOptions());
	GossipFrameNpcNameText:SetText(UnitName("npc"));
	if ( UnitExists("npc") ) then
		SetPortraitTexture(GossipFramePortrait, "npc");
	else
		GossipFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
	end

	-- Set Spacer
	local buttonCount = GossipFrame_GetTitleButtonCount();
	if buttonCount > 1 then
		GossipSpacerFrame:SetPoint("TOP", GossipFrame_GetTitleButton(buttonCount - 1), "BOTTOM", 0, 0);
	else
		GossipSpacerFrame:SetPoint("TOP", GossipGreetingText, "BOTTOM", 0, 0);
	end

	-- Update scrollframe
	GossipGreetingScrollFrame:SetVerticalScroll(0);
end

function GossipFrame_GetTitleButtonCount()
	return #GossipFrame.buttons;
end

function GossipFrame_GetTitleButton(index)
	return GossipFrame.buttons[index];
end

local function GossipFrame_AcquireTitleButton()
	local button = GossipFrame.titleButtonPool:Acquire();
	table.insert(GossipFrame.buttons, button);
	button:Show();
	return button;
end

local function GossipFrame_InsertTitleSeparator()
	if GossipFrame_GetTitleButtonCount() > 1 then
		GossipFrame.insertSeparator = true;
	end
end

local function GossipFrame_AnchorTitleButton(button)
	local buttonCount = GossipFrame_GetTitleButtonCount();
	if buttonCount > 1 then
		button:SetPoint("TOPLEFT", GossipFrame_GetTitleButton(buttonCount - 1), "BOTTOMLEFT", 0, (GossipFrame.insertSeparator and -19 or 0) - 3);
		GossipFrame.insertSeparator = false;
	else
		button:SetPoint("TOPLEFT", GossipGreetingText, "BOTTOMLEFT", -10, -20);
	end
end

function GossipTitleButton_OnClick(self, button)
	if ( self.type == "Available" ) then
		SelectGossipAvailableQuest(self:GetID());
	elseif ( self.type == "Active" ) then
		SelectGossipActiveQuest(self:GetID());
	else
		SelectGossipOption(self:GetID());
	end
end

function GossipFrameAvailableQuestsUpdate(...)
	local titleIndex = 1;
	for i=1, select("#", ...), 8 do
		local button = GossipFrame_AcquireTitleButton();
		button:SetQuest(select(i, ...));

		button:SetID(titleIndex);
		titleIndex = titleIndex + 1;

		GossipFrame_AnchorTitleButton(button);
	end
end

function GossipFrameActiveQuestsUpdate(...)
	GossipFrame_InsertTitleSeparator();

	local titleIndex = 1;
	local numActiveQuestData = select("#", ...);
	GossipFrame.hasActiveQuests = (numActiveQuestData > 0);
	for i=1, numActiveQuestData, 7 do
		local button = GossipFrame_AcquireTitleButton();
		button:SetActiveQuest(select(i, ...));

		button:SetID(titleIndex);
		titleIndex = titleIndex + 1;

		GossipFrame_AnchorTitleButton(button);
	end
end

function GossipFrameOptionsUpdate(...)
	GossipFrame_InsertTitleSeparator();

	local titleIndex = 1;
	for i=1, select("#", ...), 2 do
		local button = GossipFrame_AcquireTitleButton();
		button:SetOption(select(i, ...));

		button:SetID(titleIndex);
		titleIndex = titleIndex + 1;

		GossipFrame_AnchorTitleButton(button);
	end
end

function NPCFriendshipStatusBar_Update(frame, factionID --[[ = nil ]])
	local statusBar = NPCFriendshipStatusBar;
	local id, rep, maxRep, name, text, texture, reaction, threshold, nextThreshold = GetFriendshipReputation(factionID);
	statusBar.friendshipFactionID = id;
	if ( id and id > 0 ) then
		statusBar:SetParent(frame);
		-- if max rank, make it look like a full bar
		if ( not nextThreshold ) then
			threshold, nextThreshold, rep = 0, 1, 1;
		end
		if ( texture ) then
			statusBar.icon:SetTexture(texture);
		else
			statusBar.icon:SetTexture("Interface\\Common\\friendship-heart");
		end
		statusBar:SetMinMaxValues(threshold, nextThreshold);
		statusBar:SetValue(rep);
		statusBar:ClearAllPoints();
		statusBar:SetPoint("TOPLEFT", 73, -41);
		statusBar:Show();
	else
		statusBar:Hide();
	end
end

function NPCFriendshipStatusBar_OnEnter(self)
	ShowFriendshipReputationTooltip(self.friendshipFactionID, self, "ANCHOR_BOTTOMRIGHT");
end
