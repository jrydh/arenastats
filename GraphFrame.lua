--
-- GraphFrame.lua
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

GraphLib = LibStub:GetLibrary("LibGraph-2.0");

function ArenaStats:InitGraphFrame()
	if( self.graphFrame ) then return; end

	local f = CreateFrame( "Frame", "ArenaGraphFrame", UIParent );
	f:SetFrameStrata( "DIALOG" );
	f:SetFrameLevel( 5 );
	f:SetWidth( 500 );
	f:SetHeight( 530 );

	f:ClearAllPoints();
	f:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 );

	f:SetScript( "OnShow", function() PlaySound("igSpellBookOpen"); end );
	f:SetScript( "OnHide", function() PlaySound("igSpellBookClose"); end );

	f:SetMovable( 1 );
	f:EnableMouse( 1 );
	f:RegisterForDrag( "LeftButton" );
	f:SetScript( "OnDragStart", function() f:StartMoving(); end );
	f:SetScript( "OnDragStop", function() f:StopMovingOrSizing(); end );

	f:SetBackdrop( {
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 } } );

	-- Strings
	local s = f:CreateFontString( "ArenaGraphTeamName", "ARTWORK", "GameFontNormal" );
	s:SetPoint( "TOPLEFT", f, "TOPLEFT", 22, -20 );

	local s2 = f:CreateFontString( "ArenaGraphTeamSize", "ARTWORK", "GameFontHighlightSmall" );
	s2:SetPoint( "LEFT", s, "RIGHT", 5, 0 );

	local s3 = f:CreateFontString( "ArenaGraphHighRating", "ARTWORK", "GameFontHighlightSmall" );
	s3:SetPoint( "TOPRIGHT", f, "TOPRIGHT", -42, -20 );

	local s4 = f:CreateFontString( "ArenaGraphGridSpacing", "ARTWORK", "GameFontHighlightSmall" );
	s4:SetPoint( "BOTTOM", f, "BOTTOM", 0, 20 );

	-- Close button
	local b = CreateFrame( "Button", nil, f, UIPanelCloseButton );
	b:SetPoint( "TOPRIGHT", f, "TOPRIGHT", -3, -3 );
	b:SetScript( "OnClick", function() f:Hide(); end );
	b:SetWidth( 32 )
	b:SetHeight( 32 )
	b:SetNormalTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Up" )
	b:SetPushedTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Down" )
	b:SetHighlightTexture( "Interface/Buttons/UI-Panel-MinimizeButton-Highlight" )

	-- Graph
	local g = GraphLib:CreateGraphLine( "ArenaGraph", f, "CENTER", "CENTER", 0, -15, 470, 470 );
	f.graph = g;

	f:SetScript( "OnUpdate", function()
			if( f.needsUpdate ) then self:UpdateGraphFrame(); end
			f.needsUpdate = false;
		end );

	f.needsUpdate = true;
	self.graphFrame = f;
	tinsert( UISpecialFrames, "ArenaGraphFrame" );
end

function ArenaStats:UpdateGraphFrame()
	local games = self.db.char.games[ self.team ][ self.season ];
	local points = {};
	local xmin, xmax, ymin, ymax;
	for id = 1,games.lastGame do
		local game = games[id];
		if( game ) then
			if( not games[id-1] ) then
				tinsert( points, { id-1, game.oldRating } );
			end
			tinsert( points, { id, game.newRating } );
			if( not xmin or id < xmin ) then
				xmin = id;
			end
			if( not xmax or id > xmax ) then
				xmax = id;
			end
			if( not ymin or game.newRating < ymin ) then
				ymin = game.newRating;
			end
			if( not ymax or game.newRating > ymax ) then
				ymax = game.newRating;
			end
		end
	end

	local g = self.graphFrame.graph;
	g:ResetData();
	g:AddDataSeries( points, { 0.0, 0.0, 1.0, 1.0 } );

	local xgrid = ( xmax - xmin ) / 10;
	xgrid = max( 1, floor( xgrid/10 + 0.5 ) ) * 10;
	local ygrid = ( ymax - ymin ) / 5;
	ygrid = max( 1, floor( ygrid/25 + 0.5 ) ) * 25;

	g:SetGridSpacing( xgrid, ygrid );
	g:SetGridColor( { 0.5, 0.5, 0.5, 0.35 } );
	g:SetAxisDrawing( false, false );
	g:SetYLabels( true, false );
	g:SetXAxis( 0, points[#points][1] );
	g:LockXMin();
	g:SetAutoScale( true );
	g.NeedsUpdate = true;

	getglobal("ArenaGraphTeamName"):SetText( self.team );
	local size = self.db.char.games[ self.team ].teamSize;
	if( size ) then
		getglobal("ArenaGraphTeamSize"):SetText(
			string.format( "(%dv%d)", size, size ) );
	else
		getglobal("ArenaGraphTeamSize"):SetText( "" );
	end
	getglobal("ArenaGraphHighRating"):SetText( "High rating: " .. ymax );
	getglobal("ArenaGraphGridSpacing"):SetText(
		string.format( "Each vertical gridline represents %d games", xgrid ) );
end
