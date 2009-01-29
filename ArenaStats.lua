ArenaStats = LibStub("AceAddon-3.0"):NewAddon("ArenaStats", "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")

local AceDB = LibStub:GetLibrary("AceDB-3.0");
local AceConfigCmd = LibStub:GetLibrary("AceConfigCmd-3.0");
local AceConfigRegistry = LibStub:GetLibrary("AceConfigRegistry-3.0");

ArenaStats.version = "r5";

ArenaStats.classIcons = {
	["DEATHKNIGHT"] = "Interface\\Icons\\Spell_Deathknight_ClassIcon",
	["DRUID"] = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
	["HUNTER"] = "Interface\\Icons\\INV_Weapon_Bow_07",
	["MAGE"] = "Interface\\Icons\\INV_Staff_13",
	["PALADIN"] = "Interface\\Addons\\ArenaStats\\Images\\paladin",
	["PRIEST"] = "Interface\\Icons\\INV_Staff_30",
	["ROGUE"] = "Interface\\Addons\\ArenaStats\\Images\\rogue",
	["SHAMAN"] = "Interface\\Icons\\Spell_Nature_BloodLust", 
	["WARLOCK"] = "Interface\\Icons\\Spell_Nature_FaerieFire",
	["WARRIOR"] = "Interface\\Icons\\INV_Sword_27",
};

function ArenaStats:OnInitialize()
	local defaults = {
		char = {
			games = {}
		}
	}
	self.db = AceDB:New( "ArenaStatsDB", defaults );
	self.team = self.db.char.team or next( self.db.char.games );

	self.consoleOptions = {
		type = "group",
		args = {
			sync = {
				name = "sync",
				desc = "Synchronize all relevant data with other party members",
				type = "execute",
				func = function() ArenaStats:SynchronizeAll() end,
			},
			syncrecent = {
				name = "syncrecent",
				desc = "Synchronize all data of up to 2 weeks age",
				type = "execute",
				func = function() ArenaStats:SynchronizeRecent() end,
			},
			version = {
				name = "versionquery",
				desc = "Query party members for ArenaStats version",
				type = "execute",
				func = function() ArenaStats:VersionQuery() end,
			},
			points = {
				name = "points",
				desc = "Get the number of arena points for a rating",
				type = "input",
				set = function(info,v) ArenaStats:RatingToPoints( tonumber( v ) ) end,
			},
			rating = {
				name = "rating",
				desc = "Get the required rating to get a specified number of points",
				type = "range",
				min = 1, max = 1148,
				set = function(info,v) ArenaStats:RequiredRatingForPoints( v ) end,
			},
			games = {
				name = "games",
				desc = "Show game history",
				type = "execute",
				func = function() ArenaStats.gamesFrame:Show(); end,
			},
			stats = {
				name = "stats",
				desc = "Show class composition statistics",
				type = "execute",
				func = function() ArenaStats.statsFrame:Show(); end,
			},
			graph = {
				name = "graph",
				desc = "Show graph of team rating",
				type = "execute",
				func = function() ArenaStats.graphFrame:Show(); end,
			},
		}
	};

	AceConfigRegistry:RegisterOptionsTable( "ArenaStats", self.consoleOptions );
	AceConfigCmd:CreateChatCommand( "as", "ArenaStats" );
	AceConfigCmd:CreateChatCommand( "arenastats", "ArenaStats" );

	self:InitGamesFrame();
	self:InitGraphFrame();
	self:InitStatsFrame();
end

function ArenaStats:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
	self:RegisterComm("ARENASTATS");
	self.season = GetCurrentArenaSeason();
end

function ArenaStats:OnDisable()
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
	self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE");
	self:UnregisterComm("ARENASTATS");
end


-- Game info gathering --

function ArenaStats:ZONE_CHANGED_NEW_AREA()
	if( self.newEntry ) then
		self:Print( string.format( "%s: %d -> %d", self.newEntry.team,
			self.newEntry.game.oldRating, self.newEntry.game.newRating ) );
		self:Print( string.format( "%s: %d -> %d", self.newEntry.game.opponents.name,
			self.newEntry.opponentOldRating, self.newEntry.opponentNewRating ) );
		-- TODO: Check if GetCurrentArenaSeason bug is fixed (wrong result while in arenas)
		self:AddGame( self.newEntry.team, GetCurrentArenaSeason(), self.newEntry.id, self.newEntry.game );
		self:Synchronize( self.newEntry.team, GetCurrentArenaSeason(), self.newEntry.id );
		self.newEntry = nil;
	end
end

function ArenaStats:UPDATE_BATTLEFIELD_SCORE()
	local isArena, isRated = IsActiveBattlefieldArena();
	
	if( isArena and isRated and GetBattlefieldWinner() and not self.newEntry ) then
		self:Print( "Arena game ended" );
		local greenTeam = {};
		local goldTeam = {};
		local playerTeamIndex;
		local numCombatants = GetNumBattlefieldScores();
		for index = 1,numCombatants do
			local name, _, _, _, _, team, _, race, _, class = GetBattlefieldScore( index );
			if( name == UnitName("player") ) then
				playerTeamIndex = team;
			end
			tinsert( team == 0 and greenTeam or goldTeam, { name, race, class } );
		end
	
		local opponents = ( playerTeamIndex == 0 and goldTeam or greenTeam );
		local result = ( GetBattlefieldWinner() == playerTeamIndex ) and 1 or 0
	
		local playerTeamName, oldRating, newRating = GetBattlefieldTeamInfo( playerTeamIndex );
		opponents.name, opponentOldRating, opponentNewRating = GetBattlefieldTeamInfo( 1-playerTeamIndex );

		local noGames = self:GetTeamStats( playerTeamName );

		self.newEntry = {
			["team"] = playerTeamName,
			["id"] = noGames + 1,
			["opponentOldRating"] = opponentOldRating,
			["opponentNewRating"] = opponentNewRating,
			["game"] = {
				["timeStamp"] = date( "%a %b %d %H:%M:%S %Y" ),
				["result"] = result,
				["oldRating"] = oldRating,
				["newRating"] = newRating,
				["opponents"] = opponents,
			}
		};
	end
end

function ArenaStats:AddGame( team, season, id, game )
	if( self.db.char.games[team] and self.db.char.games[team][season] 
			and self.db.char.games[team][season][id] ) then
		self:Print( string.format( "Already have game %d (S%d) for team '%s'", id, season, team ) );
	else
		self:Print( string.format( "Adding game %d (S%d) for team '%s'", id, season, team ) );
		self.db.char.games[team] = self.db.char.games[team] or {};
		self.db.char.games[team][season] = self.db.char.games[team][season] or {};
		self.db.char.games[team][season][id] = game;
		if( not self.db.char.games[team].teamSize ) then
			self.db.char.games[team].teamSize = select( 2, self:GetTeamStats( team ) );
		end
		if( not self.db.char.games[team][season].lastGame or
			self.db.char.games[team][season].lastGame < id ) then
			self.db.char.games[team][season].lastGame = id;
		end
		self.gamesFrame.needsUpdate = true;
		self.graphFrame.needsUpdate = true;
		self.statsFrame.needsUpdate = 2;
	end
end

function ArenaStats:PurgeTeamData( team )
	self.db.char.games[team] = nil;
end

function ArenaStats:PurgeAllData()
	self.db.char.games = {};
end


-- Synchronization and communication --

function ArenaStats:SynchronizeAll()
	self:SendCommMessage( "ARENASTATS", self:Serialize( "SYNC" ), "PARTY" );
	self:QueryAllGames();
end

function ArenaStats:QueryAllGames()
	for team,tgames in pairs( self.db.char.games ) do
		for season,sgames in pairs( tgames ) do
			-- ignore non-number key entries such as teamSize, lastGame
			if( type( season ) == "number" ) then
				for id,game in pairs( sgames ) do
					if( type( id ) == "number" ) then
						self:Synchronize( team, season, id );
					end
				end
			end
		end
	end
end

function ArenaStats:SynchronizeRecent()
	self:SendCommMessage( "ARENASTATS", self:Serialize( "SYNCRECENT" ), "PARTY" );
	self:QueryRecentGames();
end

function ArenaStats:QueryRecentGames()
	local today = { ["year"] = date("%Y"), ["month"] = date("%m"), ["day"] = date("%d"),
		["hour"] = 1, ["min"] = 0, ["sec"] = 0 };
	local cutoff = time(today) - 86400*14;
	local mt = { ["Jan"] = 1, ["Feb"] = 2, ["Mar"] = 3, ["Apr"] = 4,
		["May"] = 5, ["Jun"] = 6, ["Jul"] = 7, ["Aug"] = 8,
		["Sep"] = 9, ["Oct"] = 10, ["Nov"] = 11, ["Dec"] = 12 };

	local season = GetCurrentArenaSeason();
	for team,tgames in pairs( self.db.char.games ) do
		local sgames = tgames[season];
		if( sgames ) then
			for id = sgames.lastGame,1,-1 do
				local game = sgames[id];
				if( game ) then
					local _, m, d, _, y = strsplit( " ", game.timeStamp );
					local gamet = { ["year"] = y, ["month"] = mt[m], ["day"] = d,
						["hour"] = 1, ["min"] = 0, ["sec"] = 0 };
					if( time( gamet ) < cutoff ) then break; end
					self:Synchronize( team, season, id );
				end
			end
		end
	end
end

function ArenaStats:Synchronize( team, season, id )
	self:SendCommMessage( "ARENASTATS", self:Serialize( "QUERY", { team, season, id } ), "PARTY" );
end

function ArenaStats:VersionQuery()
	self:Print( "Checking party versions..." );
	self:Print( string.format( "%s: version %s", UnitName("player"), self.version ) );
	self:SendCommMessage( "ARENASTATS", self:Serialize( "VERSIONQUERY" ), "PARTY" );
end

function ArenaStats:OnCommReceived( prefix, message, dist, sender )
	if( sender == UnitName("player") ) then return end
	local flag, cmd, m = self:Deserialize( message );
	if not flag then return end

	if( cmd == "GAME" ) then
		local team, season, id, game = unpack( m );
		self:AddGame( team, season, id, game );
	elseif( cmd == "QUERY" ) then
		local team, season, id = unpack( m );
		if( self.db.char.games[team] and
				( not self.db.char.games[team][season] or
				not self.db.char.games[team][season][id] ) ) then
			self:SendCommMessage( "ARENASTATS", self:Serialize( "REQUEST", m ), "WHISPER", sender );
		end
	elseif( cmd == "REQUEST" ) then
		local team, season, id = unpack( m );
		if( self.db.char.games[team] and self.db.char.games[team][season] and
				self.db.char.games[team][season][id] ) then
			self:SendCommMessage( "ARENASTATS", self:Serialize( "GAME",
				{ team, season, id, self.db.char.games[team][season][id] } ), "WHISPER", sender );
		end
	elseif( cmd == "SYNC" ) then
		self:QueryAllGames();
	elseif( cmd == "SYNCRECENT" ) then
		self:QueryRecentGames();
	elseif( cmd == "VERSIONQUERY" ) then
		self:SendCommMessage( "ARENASTATS", self:Serialize( "VERSION", self.version ), "WHISPER", sender );
	elseif( cmd == "VERSION" ) then
		self:Print( sender .. ": version " .. m );
	end
end


function ArenaStats:SetTeam( team )
	if( self.db.char.games[team] ) then
		self.team = team;
		self.gamesFrame.needsUpdate = true;
		self.statsFrame.needsUpdate = 2;
		self.graphFrame.needsUpdate = true;
	else
		self:Print( string.format( "Team '%s' not found. You need to play at least one rated "..
					"arena game with a team to be able to select it.", team ) );
	end
end

function ArenaStats:SetSeason( season )
	if( season <= GetCurrentArenaSeason() and season > 0 ) then
		self.season = season;
		self.gamesFrame.needsUpdate = true;
		self.statsFrame.needsUpdate = 2;
		self.graphFrame.needsUpdate = true;
	else
		self:Print( "Invalid season:", season );
	end
end

function ArenaStats:GetTeamStats( team )
	local t1,s1,_,_,_,n1 = GetArenaTeam(1);
	local t2,s2,_,_,_,n2 = GetArenaTeam(2);
	local t3,s3,_,_,_,n3 = GetArenaTeam(3);
	if( t1 and t1 == team ) then return n1, s1; end
	if( t2 and t2 == team ) then return n2, s2; end
	if( t3 and t3 == team ) then return n3, s3; end
end


-- Rating/points calculator --

local function RatingToPointsHelper( rating, teamSize )
	local points
	if rating <= 1500 then
		if( teamSize == 5 ) then
			points = floor( 0.5 + ( 0.22 * rating + 14 ) );
		elseif( teamSize == 3 ) then
			points = floor( 0.5 + ( 0.22 * rating + 14 ) * 0.88 );
		elseif( teamSize == 2 ) then
			points = floor( 0.5 + ( 0.22 * rating + 14 ) * 0.76 );
		else
			ArenaStats:Print( "Invalid team size ", teamSize );
		end
	else
		if( teamSize == 5 ) then
			points = floor( 1511.26 / ( 1 + 1639.28 * exp( -0.00412 * rating ) ) )
		elseif( teamSize == 3 ) then
			points = floor( 1511.26 / ( 1 + 1639.28 * exp( -0.00412 * rating ) ) * 0.88 )
		elseif( teamSize == 2 ) then
			points = floor( 1511.26 / ( 1 + 1639.28 * exp( -0.00412 * rating ) ) * 0.76 )
		else
			ArenaStats:Print( "Invalid team size ", teamSize );
		end
	end
	return points
end

function ArenaStats:RatingToPoints( rating )
	if( rating and rating < 0 ) then
		self:Print( "Invalid rating." );
		return;
	end
	if( rating ) then
		local points5v5 = RatingToPointsHelper( rating, 5 );
		local points3v3 = RatingToPointsHelper( rating, 3 );
		local points2v2 = RatingToPointsHelper( rating, 2 );
		self:Print( string.format( "%d rating gives %d (5v5), %d (3v3), %d (2v2) arena points.",
									rating, points5v5, points3v3, points2v2 ) );
	else
		local name1, size1, rat1 = GetArenaTeam(1);
		local name2, size2, rat2 = GetArenaTeam(2);
		local name3, size3, rat3 = GetArenaTeam(3);
		local points1, points2, points3;
		if( name1 ) then points1 = RatingToPointsHelper( rat1, size1 ); end
		if( name2 ) then points2 = RatingToPointsHelper( rat2, size2 ); end
		if( name3 ) then points3 = RatingToPointsHelper( rat3, size3 ); end

		local str = "";
		if( points1 ) then str = string.format( str .. "%d (%s)", points1, name1 ); end
		if( points2 ) then str = string.format( str .. ", %d (%s)", points2, name2 ); end
		if( points3 ) then str = string.format( str .. ", %d (%s)", points3, name3 ); end
		self:Print( str );
	end
end

function ArenaStats:RequiredRatingForPoints( points )
	local rating5v5, rating3v3, rating2v2;
	if( points <= 344 ) then
		rating5v5 = ceil( ( (points-0.5) - 14 ) / 0.22 );
	else
		rating5v5 = ceil( log( ( 1511.26 - points ) / ( 1639.28 * points ) ) / -0.00412 );
	end
	if( points <= 303 ) then
		rating3v3 = ceil( ( (points-0.5)/0.88 - 14 ) / 0.22 );
	elseif( points <= 1329 ) then
		rating3v3 = ceil( log( ( 1511.26 - points/0.88 ) / ( 1639.28 * points/0.88 ) ) / -0.00412 );
	end
	if( points <= 261 ) then
		rating2v2 = ceil( ( (points-0.5)/0.76 - 14 ) / 0.22 );
	elseif( points <= 1148 ) then
		rating2v2 = ceil( log( ( 1511.26 - points/0.76 ) / ( 1639.28 * points/0.76 ) ) / -0.00412 );
	end
	local str = string.format( "%d points requires %d (5v5)", points, rating5v5 );
	if( rating3v3 ) then str = string.format( str .. ", %d (3v3)", rating3v3 ); end
	if( rating2v2 ) then str = string.format( str .. ", %d (2v2)", rating2v2 ); end
	str = str .. " rating.";
	self:Print( str );
end
