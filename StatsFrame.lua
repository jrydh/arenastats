--
-- StatsFrame.lua
-- Copyright 2008, 2009 Johannes Rydh
--
-- ArenaStats is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

-- TODO:
-- scroll bar

function ArenaStats:InitStatsFrame()
	if( self.statsFrame ) then return; end

	local f = CreateFrame( "Frame", "ArenaStatsFrame", UIParent );
	f:SetFrameStrata( "DIALOG" );
	f:SetFrameLevel( 5 );
	f:SetWidth( 365 );
	f:SetHeight( 355 );

	f:SetMovable( 1 );
	f:EnableMouse( 1 );
	f:RegisterForDrag( "LeftButton" );
	f:SetScript( "OnDragStart", function() f:StartMoving(); end );
	f:SetScript( "OnDragStop", function() f:StopMovingOrSizing(); end );

	f:ClearAllPoints();
	f:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 );
	
	f:SetScript( "OnShow", function() PlaySound("igSpellBookOpen"); end );
	f:SetScript( "OnHide", function() PlaySound("igSpellBookClose"); end );
	
	local t = f:CreateTexture( nil, "BACKGROUND" );
	t:SetTexture( "Interface/PVPFrame/UI-Character-PVP-Elements" );
	t:SetTexCoord( 0, 0.703125, 0, 0.693359375 );
	t:SetAllPoints( f );
	
	local s = f:CreateFontString( "ArenaStatsFrameTeamName", "ARTWORK", "GameFontNormal" );
	s:SetPoint( "TOPLEFT", f, "TOPLEFT", 22, -20 );

	local s2 = f:CreateFontString( "ArenaStatsFrameTeamSize", "ARTWORK", "GameFontHighlightSmall" );
	s2:SetPoint( "LEFT", s, "RIGHT", 5, 0 );

	local s3 = f:CreateFontString( "ArenaStatsFrameDisplayType", "ARTWORK", "GameFontHighlightSmall" );
	s3:SetPoint( "TOPLEFT", s, "BOTTOMLEFT", 0, -30 );

	local s4 = f:CreateFontString( "ArenaStatsFrameTotalGamesLabel", "ARTWORK", "GameFontDisableSmall" );
	s4:SetPoint( "CENTER", f, "TOP", -30, -55 );
	s4:SetText( "Games" );

	local s5 = f:CreateFontString( "ArenaStatsFrameTotalGames", "ARTWORK", "GameFontHighLightSmall" );
	s5:SetPoint( "TOP", s4, "BOTTOM", 0, -6 );

	local s6 = f:CreateFontString( "ArenaStatsFrameWinLossLabel", "ARTWORK", "GameFontDisableSmall" );
	s6:SetPoint( "CENTER", s4, "CENTER", 52, 0 );
	s6:SetText( "Win - Loss" );

	local s7 = f:CreateFontString( "ArenaStatsFrameWinLoss", "ARTWORK", "GameFontHighLightSmall" );
	s7:SetPoint( "TOP", s6, "BOTTOM", 0, -6 );

	local t2 = f:CreateTexture( nil, "ARTWORK" );
	t2:SetTexture( "Interface/PVPFrame/UI-Character-PVP-Elements" );
	t2:SetWidth( 280 );
	t2:SetHeight( 3 );
	t2:SetPoint( "TOP", f, "TOP", 3, -40 );
	t2:SetTexCoord( 0, 0.4140625, 0.76171875, 0.765625 );

	-- Close button
	local b = CreateFrame( "Button", nil, f, UIPanelCloseButton );
	b:SetPoint( "TOPRIGHT", f, "TOPRIGHT", 1, 1 );
	b:SetScript( "OnClick", function() f:Hide(); end );
	b:SetWidth( 32 );
	b:SetHeight( 32 );
	b:SetNormalTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Up" );
	b:SetPushedTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Down" );
	b:SetHighlightTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Highlight" );

	-- Column headers
	local labels = { "Classes", "Games", "Wins - Loss", "Win %" };
	local width = { 153, 55, 75, 55 };	
	for i = 1,4 do
		local b = CreateFrame( "Button", "ArenaStatsFrameHeader"..i, f );
		if( i == 1 ) then
			b:SetPoint( "TOPLEFT", f, "TOPLEFT", 19, -90 );
		else
			b:SetPoint( "LEFT", "ArenaStatsFrameHeader"..i-1, "RIGHT", -2, 0 );
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
		b:SetScript( "OnClick", function()
			if( f.sortBy == i ) then f.sortBy = -i; else f.sortBy = i; end
			ArenaStats:SortStatsData(); f.needsUpdate = 1; end );
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
	for i = 1,10 do
		local b = CreateFrame( "Button", "ArenaStatsFrameEntry"..i, f );
		b:SetPoint( "TOPLEFT", "ArenaStatsFrameHeader1", "BOTTOMLEFT", 0, 16-i*19 )
		b:SetWidth( 330 );
		b:SetHeight( 16 );
		local highlight = b:CreateTexture( nil, "HIGHLIGHT" );
		highlight:SetTexture( "Interface/QuestFrame/UI-QuestTitleHighlight" );
		highlight:SetPoint( "LEFT", b, "LEFT" );
		highlight:SetPoint( "RIGHT", b, "RIGHT" );
		b:SetHighlightTexture( highlight, "ADD" );

		b:EnableMouseWheel(1);
		b:SetScript( "OnMouseWheel", function( frame, d )
				f.offset = f.offset - d; f.needsUpdate = 1; end );

		local classFrame = CreateFrame( "Frame", nil, b );
		classFrame:SetWidth( 143 );
		classFrame:SetHeight( 14 );
		classFrame:SetPoint( "LEFT", "ArenaStatsFrameHeader1", "LEFT", 5, 0 );
		classFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		for j = 1,5 do
			local classIcon = classFrame:CreateTexture(
				"ArenaStatsFrameEntry"..i.."Class"..j, "BACKGROUND" );
			classIcon:SetPoint( "LEFT", classFrame, "LEFT", (j-1)*18, 0 );
			classIcon:SetWidth( 16 );
			classIcon:SetHeight( 16 );
		end

		local gamesFrame = CreateFrame( "Frame", nil, b );
		gamesFrame:SetWidth( 45 );
		gamesFrame:SetHeight( 14 );
		gamesFrame:SetPoint( "LEFT", "ArenaStatsFrameHeader2", "LEFT", 5, 0 );
		gamesFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local gamesLabel = gamesFrame:CreateFontString( "ArenaStatsFrameEntry"..i.."Games",
			"BACKGROUND", "GameFontHighlightSmall" );
		gamesLabel:SetAllPoints( gamesFrame );
		gamesLabel:SetJustifyH( "CENTER" );
		
		local winsFrame = CreateFrame( "Frame", nil, b );
		winsFrame:SetWidth( 39 );
		winsFrame:SetHeight( 14 );
		winsFrame:SetPoint( "LEFT", "ArenaStatsFrameHeader3", "LEFT", 5, 0 );
		winsFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local winsLabel = winsFrame:CreateFontString( "ArenaStatsFrameEntry"..i.."Wins",
			"BACKGROUND", "GameFontHighlightSmall" );
		winsLabel:SetAllPoints( winsFrame );
		winsLabel:SetJustifyH( "RIGHT" );

		local lossesFrame = CreateFrame( "Frame", nil, b );
		lossesFrame:SetWidth( 26 );
		lossesFrame:SetHeight( 14 );
		lossesFrame:SetPoint( "RIGHT", "ArenaStatsFrameHeader3", "RIGHT", -5, 0 );
		lossesFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local lossesLabel = lossesFrame:CreateFontString( "ArenaStatsFrameEntry"..i.."Losses",
			"BACKGROUND", "GameFontHighlightSmall" );
		lossesLabel:SetAllPoints( lossesFrame );
		lossesLabel:SetJustifyH( "LEFT" );

		local winpctFrame = CreateFrame( "Frame", nil, b );
		winpctFrame:SetWidth( 45 );
		winpctFrame:SetHeight( 14 );
		winpctFrame:SetPoint( "LEFT", "ArenaStatsFrameHeader4", "LEFT", 5, 0 );
		winpctFrame:SetPoint( "TOP", b, "TOP", 0, -1 );
		local winpctLabel = winpctFrame:CreateFontString( "ArenaStatsFrameEntry"..i.."WinPct",
			"BACKGROUND", "GameFontHighlightSmall" );
		winpctLabel:SetAllPoints( winpctFrame );
		winpctLabel:SetJustifyH( "CENTER" );
	end
	
	-- Toggle button
	local b = CreateFrame( "Button", "ArenaStatsFrameToggleButton", f );
	b:SetWidth( 32 );
	b:SetHeight( 32 );
	b:SetPoint( "BOTTOMRIGHT", f, "BOTTOMRIGHT", -17, 17 );
	b:SetNormalTexture( "Interface/Buttons/UI-SpellbookIcon-NextPage-Up" )
	b:SetPushedTexture( "Interface/Buttons/UI-SpellbookIcon-NextPage-Down" )
	b:SetDisabledTexture( "Interface/Buttons/UI-SpellbookIcon-NextPage-Disabled" )
	b:SetHighlightTexture( "Interface/Buttons/UI-Common-MouseHilight", "ADD" )
	b:SetScript( "OnClick", function()
			f.displayWeek = not f.displayWeek;
			f.needsUpdate = 2;
			PlaySound("igMainMenuOptionCheckBoxOn");
		end );
	local s = f:CreateFontString( "ArenaStatsFrameToggleButtonLabel", "ARTWORK", "GameFontNormalSmall" );
	s:SetJustifyH( "RIGHT" );
	s:SetPoint( "RIGHT", b, "LEFT", -2, 0 );

	f:SetScript( "OnUpdate", function()
			if( f.needsUpdate > 1 ) then self:CompileStatsData(); end
			if( f.needsUpdate > 0 ) then self:UpdateStatsFrame(); end
			f.needsUpdate = 0;
		end );
	
	self.statsFrame = f;
	tinsert( UISpecialFrames, "ArenaStatsFrame" );

	self.statsFrame.displayWeek = false;
	self.statsFrame.sortBy = 2;
	self.statsFrame.needsUpdate = 2;
end

function ArenaStats:CompileStatsData()
	if( not self.db.char.games[ self.team ] or
		not self.db.char.games[ self.team ][ self.season ] ) then return end

	local games = self.db.char.games[ self.team ][ self.season ];

	local today = { ["year"] = date("%Y"), ["month"] = date("%m"), ["day"] = date("%d"),
		["hour"] = 1, ["min"] = 0, ["sec"] = 0 };
	local weekstart = time(today) - 86400*mod( date("%u")+4, 7 );

	local t = {};
	local total, wins = 0, 0;
	for id = games.lastGame,1,-1 do
		local game = games[ id ];
		if( game ) then
			if( self.statsFrame.displayWeek ) then
				local _, m, d, _, y = strsplit( " ", game.timeStamp );
				local mt = { ["Jan"] = 1, ["Feb"] = 2, ["Mar"] = 3, ["Apr"] = 4,
					["May"] = 5, ["Jun"] = 6, ["Jul"] = 7, ["Aug"] = 8,
					["Sep"] = 9, ["Oct"] = 10, ["Nov"] = 11, ["Dec"] = 12 };
				local gamet = { ["year"] = y, ["month"] = mt[m], ["day"] = d,
					["hour"] = 1, ["min"] = 0, ["sec"] = 0 };
				if( time( gamet ) < weekstart ) then break; end
			end

			local st = {};
			for _,o in ipairs( game.opponents ) do
				tinsert( st, o[3] );
			end
			sort( st );
			local cc = table.concat( st, " " );
			if( cc ) then
				t[cc] = t[cc] or {};
				t[cc].total = ( t[cc].total or 0 ) + 1
				t[cc].wins = ( t[cc].wins or 0 ) + game.result
				t[cc].class = st;
				total = total + 1;
				wins = wins + game.result;
			end
		end
	end
	local size = self.db.char.games[ self.team ].teamSize;
	getglobal("ArenaStatsFrameTeamName"):SetText( self.team );
	if( size ) then
		getglobal("ArenaStatsFrameTeamSize"):SetText(
			string.format( "(%dv%d)", size, size ) );
	else
		getglobal("ArenaStatsFrameTeamSize"):SetText( "" );
	end
	getglobal("ArenaStatsFrameTotalGames"):SetText( total );
	getglobal("ArenaStatsFrameWinLoss"):SetText( wins.." - "..(total-wins) );
	self.statsFrame.data = {};
	for cc,data in pairs( t ) do
		tinsert( self.statsFrame.data, data );
	end
	self.statsFrame.offset = 0;
	self:SortStatsData();
end

function ArenaStats:UpdateStatsFrame()
	if( self.statsFrame.offset > #self.statsFrame.data - 10 ) then
		self.statsFrame.offset = #self.statsFrame.data - 10;
	end
	if( self.statsFrame.offset < 0 ) then
		self.statsFrame.offset = 0;
	end
	
	if( self.statsFrame.displayWeek ) then
		getglobal( "ArenaStatsFrameDisplayType" ):SetText( "THIS WEEK" );
		getglobal( "ArenaStatsFrameToggleButtonLabel" ):SetText( "View this Week's Stats" );
	else
		getglobal( "ArenaStatsFrameDisplayType" ):SetText( "THIS SEASON" );
		getglobal( "ArenaStatsFrameToggleButtonLabel" ):SetText( "View this Season's Stats" );
	end
	
	for i = 1,10 do
	 	local data = self.statsFrame.data[i+self.statsFrame.offset];
		if( data ) then
			getglobal( "ArenaStatsFrameEntry"..i ):Show();
			for j,class in ipairs( data.class ) do
				local texture = self.classIcons[class] or "Interface\\Icons\\INV_Misc_QuestionMark";
				getglobal( "ArenaStatsFrameEntry"..i.."Class"..j ):SetTexture( texture );
			end
			for j = #data.class+1,5 do
				getglobal( "ArenaStatsFrameEntry"..i.."Class"..j ):SetTexture( nil );
			end
			getglobal( "ArenaStatsFrameEntry"..i.."Games" ):SetText( data.total );
			getglobal( "ArenaStatsFrameEntry"..i.."Wins" ):SetText( data.wins.." - " );
			getglobal( "ArenaStatsFrameEntry"..i.."Losses" ):SetText( data.total - data.wins );
			getglobal( "ArenaStatsFrameEntry"..i.."WinPct" ):SetText(
				floor( 0.5 + 100*data.wins/data.total ).."%" );
		else
			getglobal( "ArenaStatsFrameEntry"..i ):Hide();
		end
	end
end

function ArenaStats:SortStatsData()
	local comp = {
		[1] = function(a,b)
				for i = 1,5 do
					if( a.class[i] == b.class[i] ) then
						if( not b.class[i+1] ) then return true; end
						if( not a.class[i+1] ) then return false; end
					else
						return a.class[i] >= b.class[i];
					end
				end
			end,
		[-1] = function(a,b)
				for i = 1,5 do
					if( a.class[i] == b.class[i] ) then
						if( not b.class[i+1] ) then return true; end
						if( not a.class[i+1] ) then return false; end
					else
						return a.class[i] < b.class[i];
					end
				end
			end,
		[2] = function(a,b) return a.total >= b.total; end,
		[-2] = function(a,b) return a.total < b.total; end,
		[3] = function(a,b) return a.wins >= b.wins; end,
		[-3] = function(a,b) return a.wins < b.wins; end,
		[4] = function(a,b) return a.wins/a.total >= b.wins/b.total; end,
		[-4] = function(a,b) return a.wins/a.total < b.wins/b.total; end,
	};

	local c = comp[ self.statsFrame.sortBy ];
	self.statsFrame.data = mergesort( self.statsFrame.data, c );

	self.statsFrame.offset = 0;
end

-- using mergesort since table.sort is not stable
function mergesort( m, comp )
	if( not comp ) then comp = function(a,b) return a < b; end; end

	local left, right, result = {}, {}, {};
	if( #m <= 1 ) then return m; end
	local middle = floor(#m/2);
	for i = 1,middle do
		tinsert( left, m[i] );
	end
	for i = middle+1,#m do
		tinsert( right, m[i] );
	end

	left = mergesort( left, comp );
	right = mergesort( right, comp );
	result = merge( left, right, comp );

	return result;
end

function merge( left, right, comp )
	local result, i, j = {}, 1, 1;
	while left and i <= #left and right and j <= #right do
		if( comp( left[i], right[j] ) ) then
			tinsert( result, left[i] );
			i = i + 1;
		else
			tinsert( result, right[j] );
			j = j + 1;
		end
	end
	while left and i <= #left do
		tinsert( result, left[i] );
		i = i + 1;
	end
	while right and j <= #right do
		tinsert( result, right[j] );
		j = j + 1;
	end
	return result;
end
