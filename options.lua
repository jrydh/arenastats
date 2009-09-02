--
-- options.lua
-- Copyright 2009 Johannes Rydh
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

local function ArenaStats_InitializeTeamDropDown( frame )
	local info = UIDropDownMenu_CreateInfo();
	for team,tdata in pairs( ArenaStats.db.char.games ) do
		local size = tdata.teamSize;
		for season,sdata in pairs( tdata ) do
			if type( season ) == "number" then
				info.text = string.format( "%s (season %d)", team, season );
				info.func = function( button )
						UIDropDownMenu_SetSelectedName( button.owner, button.value );
					end;
				info.owner = frame;
				info.checked = ( UIDropDownMenu_GetSelectedName( frame ) == team );
				UIDropDownMenu_AddButton( info, 1 );
			end
		end
	end
end

local function confirm( func )
	StaticPopupDialogs["AS_CLEAR_WARNING"].OnAccept = func;
	StaticPopup_Show( "AS_CLEAR_WARNING" );
end

function ArenaStats:SetupOptions( defaults )
	if self.optionsFrame then return; end
	
	StaticPopupDialogs["AS_CLEAR_WARNING"] = {
		text = "Really delete this data?",
		button1 = OKAY,
		button2 = CANCEL,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		sound = "igCharacterInfoClose"
	};

	local f = CreateFrame( "Frame", "ArenaStatsOptionsFrame" );
	self.optionsFrame = f;
	
	local text = f:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	text:SetPoint( "TOPLEFT", 16, -16 );
	text:SetText( "ArenaStats" );

	local subtext = f:CreateFontString( nil, "ARTWORK",
	                          "GameFontHighlightSmall" );
	subtext:SetHeight( 32 );
	subtext:SetPoint( "TOPLEFT", text, "BOTTOMLEFT", 0, -8 );
	subtext:SetPoint( "RIGHT", f, -32, 0 );
	subtext:SetNonSpaceWrap( true );
	subtext:SetJustifyH( "LEFT" );
	subtext:SetJustifyV( "TOP" );
	subtext:SetText( "Gathers statistics of your arena games" );
	
	local s = f:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
	s:SetText( "Arena team" );
	s:SetPoint( "TOPLEFT", f, "TOPLEFT", 16, -80 );
	
	local teamDropdown = CreateFrame( "Button", "ArenaStatsTeamDropDown",
	                                         f, "UIDropDownMenuTemplate" );
	teamDropdown:SetPoint( "LEFT", s, "LEFT", 60, 0 );
	UIDropDownMenu_SetWidth( teamDropdown, 150 );
	UIDropDownMenu_Initialize( teamDropdown,
		ArenaStats_InitializeTeamDropDown );
	teamDropdown:SetScript( "OnClick", function( self )
		ToggleDropDownMenu( 1, nil, self, self, 0, 0 );
	end );

	local clearTeam = CreateFrame( "Button", nil, f, "UIPanelButtonTemplate" );
	clearTeam:SetWidth( 120 );
	clearTeam:SetHeight( 22 );
	clearTeam:SetPoint( "TOPLEFT", s, "BOTTOMLEFT", 0, -10 );
	clearTeam:SetText( "Clear this team" );
	clearTeam:SetScript( "OnClick", function() confirm( function()
		local s = UIDropDownMenu_GetSelectedName( teamDropdown );
		if s then
			local team, season = s:match( "(.+) %(season (%d+)%)" );
			self:PurgeTeamData( team, tonumber(season) );
		end
	end ) end );

	local clearAll = CreateFrame( "Button", nil, f, "UIPanelButtonTemplate" );
	clearAll:SetWidth( 120 );
	clearAll:SetHeight( 22 );
	clearAll:SetPoint( "TOPLEFT", clearTeam, "BOTTOMLEFT", 0, -8 );
	clearAll:SetText( "Clear all data" );
	clearAll:SetScript( "OnClick", function()
		confirm( function() self:PurgeAllData(); end ) end );

	f.name = "ArenaStats";
	f.okay = function()
		local s = UIDropDownMenu_GetSelectedName( teamDropdown );
		if s then
			local team, season = s:match( "(.+) %(season (%d+)%)" );
			self:SetTeam( team, tonumber(season) );
		end
	end;
	f.cancel = function()
		local team, season = self.db.char.team, self.db.char.season;
		if team and season then
			local s = string.format( "%s (season %d)", team, season );
			UIDropDownMenu_SetSelectedName( teamDropdown, s );
		else
			UIDropDownMenu_SetSelectedName( teamDropdown, "" );
		end
	end;
	f.cancel();
	InterfaceOptions_AddCategory( f );
end
