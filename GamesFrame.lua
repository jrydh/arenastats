

function ArenaStats:InitGamesFrame()
	if( self.gamesFrame ) then return; end

	local f = CreateFrame( "Frame", "ArenaGamesFrame", UIParent );
	f:SetFrameStrata( "DIALOG" );
	f:SetFrameLevel( 5 );
	f:SetWidth( 384 );
	f:SetHeight( 512 );

	f:SetMovable( 1 );
	f:EnableMouse( 1 );
	f:RegisterForDrag( "LeftButton" );
	f:SetScript( "OnDragStart", function() f:StartMoving(); end );
	f:SetScript( "OnDragStop", function() f:StopMovingOrSizing(); end );

	f:ClearAllPoints();
	f:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 );
	
	f:SetScript( "OnShow", function()
			SetPortraitTexture( getglobal("ArenaGamesPortrait"), "player" );
			PlaySound("igSpellBookOpen");
		end );
	f:SetScript( "OnHide", function() PlaySound("igSpellBookClose"); end );

	f:SetScript( "OnUpdate", function()
			if( f.needsUpdate ) then self:UpdateGamesFrame(); end
			f.needsUpdate = false;
		end );

	local p = f:CreateTexture( "ArenaGamesPortrait", "BACKGROUND" );
	p:SetPoint( "TOPLEFT", f, "TOPLEFT", 9, -6 );

	local s = f:CreateFontString( nil, "BORDER", "GameFontNormal" );
	s:SetText( "ArenaStats" );
	s:SetPoint( "TOP", f, "TOP", 3, -19 );

	local t = f:CreateTexture( nil, "BORDER" );
	t:SetTexture( "Interface/PaperDollInfoFrame/UI-Character-General-TopLeft" );
	t:SetPoint( "TOPLEFT", f, "TOPLEFT", 2, -1 );

	local t = f:CreateTexture( nil, "BORDER" );
	t:SetTexture( "Interface/PaperDollInfoFrame/UI-Character-General-TopRight" );
	t:SetPoint( "TOPLEFT", f, "TOPLEFT", 258, -1 );

	local t = f:CreateTexture( nil, "BORDER" );
	t:SetTexture( "Interface/PaperDollInfoFrame/UI-Character-General-BottomLeft" );
	t:SetPoint( "TOPLEFT", f, "TOPLEFT", 2, -257 );

	local t = f:CreateTexture( nil, "BORDER" );
	t:SetTexture( "Interface/PaperDollInfoFrame/UI-Character-General-BottomRight" );
	t:SetPoint( "TOPLEFT", f, "TOPLEFT", 258, -257 );

	-- Close button
	local b = CreateFrame( "Button", nil, f, UIPanelCloseButton );
	b:SetPoint( "TOPRIGHT", f, "TOPRIGHT", -29, -9 );
	b:SetScript( "OnClick", function() f:Hide(); end );
	b:SetWidth( 32 );
	b:SetHeight( 32 );
	b:SetNormalTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Up" )
	b:SetPushedTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Down" )
	b:SetHighlightTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Highlight" )

	-- Column headers
	local labels = { "Game", "Opponents", "Result", "Rating" };
	local width = { 45, 133, 45, 55 };
	for i = 1,4 do
		local b = CreateFrame( "Button", "ArenaGamesFrameHeader"..i, f );
		if( i == 1 ) then
			b:SetPoint( "TOPLEFT", f, "TOPLEFT", 23, -75 );
		else
			b:SetPoint( "LEFT", "ArenaGamesFrameHeader"..i-1, "RIGHT", -2, 0 );
		end
		b:SetWidth( width[i] );
		b:SetHeight( 24 );
		local tLeft = b:CreateTexture( nil, "BACKGROUND" );
		tLeft:SetTexture( "Interface/FriendsFrame/WhoFrame-ColumnTabs" );
		tLeft:SetWidth( 5 );
		tLeft:SetHeight( 24 );
		tLeft:SetPoint( "TOPLEFT", b, "TOPLEFT" );
		tLeft:SetTexCoord( 0, 0.078125, 0, 0.75 );
		tMid = b:CreateTexture( nil, "BACKGROUND" );
		tMid:SetTexture( "Interface/FriendsFrame/WhoFrame-ColumnTabs" );
		tMid:SetWidth( width[i]-9 );
		tMid:SetHeight( 24 );
		tMid:SetPoint( "LEFT", tLeft, "RIGHT" );
		tMid:SetTexCoord( 0.078125, 0.90625, 0, 0.75 );
		tRight = b:CreateTexture( nil, "BACKGROUND" );
		tRight:SetTexture( "Interface/FriendsFrame/WhoFrame-ColumnTabs" );
		tRight:SetWidth( 4 );
		tRight:SetHeight( 24 );
		tRight:SetPoint( "LEFT", tMid, "RIGHT" );
		tRight:SetTexCoord( 0.90625, 0.96875, 0, 0.75 );
		local l = b:CreateFontString( nil, "HIGHLIGHT", "GameFontHighlightSmall" );
		l:SetText( labels[i] );
		l:SetPoint( "CENTER", b, "CENTER" );
		b:SetFontString( l );
		tHigh = b:CreateTexture( nil, "HIGHLIGHT" );
		tHigh:SetTexture( "Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight" );
		tHigh:SetPoint( "TOPLEFT", tLeft, "TOPLEFT", -2, 5 );
		tHigh:SetPoint( "BOTTOMRIGHT", tRight, "BOTTOMRIGHT", 2, -7 );
		b:SetHighlightTexture( tHigh, "ADD" );
	end

	-- List "buttons"
	for i = 1,13 do
		local b = CreateFrame( "Button", "ArenaGamesFrameEntry"..i, f );
		b:SetPoint( "TOPLEFT", "ArenaGamesFrameHeader1", "BOTTOMLEFT", 0, 16-i*19 )
		b:SetWidth( 278 );
		b:SetHeight( 16 );
		local highlight = b:CreateTexture( nil, "HIGHLIGHT" );
		highlight:SetTexture( "Interface/QuestFrame/UI-QuestTitleHighlight" );
		highlight:SetPoint( "LEFT", b, "LEFT" );
		highlight:SetPoint( "RIGHT", b, "RIGHT" );
		b:SetHighlightTexture( highlight, "ADD" );

		b:EnableMouseWheel(1);
		b:SetScript( "OnMouseWheel", function( frame, d )
				f.offset = f.offset - d; f.needsUpdate = true; end );

		local gameFrame = CreateFrame( "Frame", nil, b );
		gameFrame:SetWidth( width[1]-10 );
		gameFrame:SetHeight( 14 );
		gameFrame:SetPoint( "LEFT", "ArenaGamesFrameHeader1", "LEFT", 5, 0 );
		gameFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local gameLabel = gameFrame:CreateFontString( "ArenaGamesFrameEntry"..i.."Game",
			"BACKGROUND", "GameFontHighlightSmall" );
		gameLabel:SetAllPoints( gameFrame );
		gameLabel:SetJustifyH( "CENTER" );

		local classFrame = CreateFrame( "Frame", nil, b );
		classFrame:SetWidth( width[2]-10 );
		classFrame:SetHeight( 14 );
		classFrame:SetPoint( "LEFT", "ArenaGamesFrameHeader2", "LEFT", 5, 0 );
		classFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		for j = 1,5 do
			local classIcon = classFrame:CreateTexture(
				"ArenaGamesFrameEntry"..i.."Class"..j, "BACKGROUND" );
			classIcon:SetPoint( "LEFT", classFrame, "LEFT", (j-1)*18, 0 );
			classIcon:SetWidth( 16 );
			classIcon:SetHeight( 16 );
		end

		local resultFrame = CreateFrame( "Frame", nil, b );
		resultFrame:SetWidth( width[3]-10 );
		resultFrame:SetHeight( 14 );
		resultFrame:SetPoint( "LEFT", "ArenaGamesFrameHeader3", "LEFT", 5, 0 );
		resultFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local resultLabel = resultFrame:CreateFontString( "ArenaGamesFrameEntry"..i.."Result",
			"BACKGROUND", "GameFontHighlightSmall" );
		resultLabel:SetAllPoints( resultFrame );
		resultLabel:SetJustifyH( "CENTER" );

		local ratingFrame = CreateFrame( "Frame", nil, b );
		ratingFrame:SetWidth( width[4]-10 );
		ratingFrame:SetHeight( 14 );
		ratingFrame:SetPoint( "LEFT", "ArenaGamesFrameHeader4", "LEFT", 5, 0 );
		ratingFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local ratingLabel = ratingFrame:CreateFontString( "ArenaGamesFrameEntry"..i.."Rating",
			"BACKGROUND", "GameFontHighlightSmall" );
		ratingLabel:SetAllPoints( ratingFrame );
		ratingLabel:SetJustifyH( "CENTER" );
	end
	
	local s = CreateFrame( "Slider", "ArenaGamesSlider", f );
	s:SetBackdrop( {
		bgFile = "Interface\Buttons\UI-SliderBar-Background",
		edgeFile = "Interface\Buttons\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 } } );
	s:SetThumbTexture( "Interface\Buttons\UI-SliderBar-Button-Vertical" );
	s:SetOrientation( "VERTICAL" );
	s:SetWidth( 16 );
	s:SetHeight( 128 );
--	s:SetPoint( "TOPRIGHT", f, "TOPRIGHT", -30, -99 );
	s:SetPoint( "CENTER", f, "CENTER" );
	s:SetMinMaxValues( 0, 50 );
	s:SetValue( 0 );
	s:SetValueStep( 1 );
		
	self.gamesFrame = f;
	tinsert( UISpecialFrames, "ArenaGamesFrame" );
	self.gamesFrame.offset = 0;
	self.gamesFrame.needsUpdate = true;

	StaticPopupDialogs["AS_SET_GAME_COMMENT"] = {
		text = "Set comments for game %d:",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		hasWideEditBox = 1,
		maxLetters = 256,
		OnShow = function( self )
			self.wideEditBox:SetText( ArenaStats.gamesFrame.commentedGame.comment or "" );
			self.wideEditBox:SetFocus();
		end,
		OnAccept = function( self )
			local text = self.wideEditBox:GetText();
			ArenaStats.gamesFrame.commentedGame.comment = text;
		end,
		EditBoxOnEnterPressed = function( self )
			local parent = self:GetParent();
			local text = parent.wideEditBox:GetText();
			ArenaStats.gamesFrame.commentedGame.comment = ( text == "" and nil or text );
			parent:Hide();
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide();
		end,
		OnHide = function()
			ArenaStats.gamesFrame.commentedGame = nil;
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		sound = "igCharacterInfoClose"
	};
end

function ArenaStats:UpdateGamesFrame()
	if( not self.db.char.games[ self.team ] or
		not self.db.char.games[ self.team ][ self.season ] ) then
		return;
	end
	local games = self.db.char.games[ self.team ][ self.season ];

--	if( self.gamesFrame.offset > games.lastGame - 13 ) then
--		self.gamesFrame.offset = games.lastGame - 13;
--	end
	if( self.gamesFrame.offset < 0 ) then
		self.gamesFrame.offset = 0;
	end

	local id = games.lastGame - self.gamesFrame.offset;
	for i = 1,13 do
		local game = games[id];
		while( not game and id > 0 ) do
			id = id - 1;
			game = games[id];
		end
		local x = getglobal("ArenaGamesFrameEntry"..i);
		if( game ) then
			x:Show();
			getglobal("ArenaGamesFrameEntry"..i.."Game"):SetText( id );
			for j,opp in ipairs( game.opponents ) do
				local texture = self.classIcons[opp[3]] or "Interface\\Icons\\INV_Misc_QuestionMark";
				getglobal( "ArenaGamesFrameEntry"..i.."Class"..j ):SetTexture( texture );
			end
			for j = #game.opponents+1,5 do
				getglobal( "ArenaGamesFrameEntry"..i.."Class"..j ):SetTexture( nil );
			end
			getglobal("ArenaGamesFrameEntry"..i.."Result"):SetText( game.result );
			getglobal("ArenaGamesFrameEntry"..i.."Rating"):SetText( game.newRating );
			x:SetScript( "OnEnter", function()
				GameTooltip:SetOwner( x, "ANCHOR_RIGHT" );
				GameTooltip:SetText( game.opponents.name );
				for j,opp in ipairs( game.opponents ) do
					GameTooltip:AddLine( string.format( "%s, %s %s", opp[1], opp[2], opp[3] ), 1, 1, 1 );
				end
				GameTooltip:AddLine( "\n"..game.timeStamp, 1, 1, 1 );
				local r, g, b = 1-game.result, game.result, 0;
				GameTooltip:AddLine( string.format( "%s, %d -> %d",
				 	game.result == 1 and "WIN" or "LOSS",
					game.oldRating, game.newRating ), r, g, b );
				if( game.comment ) then
					GameTooltip:AddLine( game.comment, 0, 0.82, 1 );
				end
				GameTooltip:Show();
			end );
			x:SetScript( "OnLeave", function() GameTooltip:Hide() end );
			x:SetScript( "OnClick", function()
				self.gamesFrame.commentedGame = game;
				StaticPopup_Show( "AS_SET_GAME_COMMENT", id );
			end );
			
			id = id - 1;
		else
			x:Hide();
		end
	end
end
