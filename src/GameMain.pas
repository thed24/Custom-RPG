program GameMain;
uses SwinGame, sgTypes, SysUtils, sgUserInterface;

type
	Player1Stats = record //creates record for player stats
		Strength, Intelligence, Speed, Wisdom, Dexterity : Integer;
		HP, MP : Integer;
	end;

	Player2Stats = record //creates record for player 2 stats
		Strength, Intelligence, Speed, Wisdom, Dexterity : Integer;
		HP, MP : Integer;
	end;

	Skills = record //creates record for skill damage
		SkillPower : Integer;
		SkillAccuracy : Integer;
	end;

	MeleeSkills = array [0..2] of Skills; //creates array of skills
		
	MagicSkills = array [0..3] of Skills;

	RangedSkills = array [0..2] of Skills;
		
	SelfSkills = array [0..1] of Skills;

	BuffSkills = array [0..4] of Skills;

var MultiplayerConnection : Connection; 
	RequiredIP : string;
	LoopLock : boolean;
	Victory : integer = 0;
	Loss : integer = 0;

procedure LoadResources();


begin
	LoadBitmapNamed('MainMenuBackground', 'MainMenu.png');
	LoadBitmapNamed('MainMenuBackground2', 'MainMenu2.png');
	LoadBitmapNamed('IPSelectScreen', 'MainMenu3.png');
	LoadBitmapNamed('GameOverScreen', 'GameOver.png'); 
	LoadBitmapNamed('VictoryScreen', 'Victory.png'); 
	LoadBitmapNamed('Background', 'Background.png'); 
end;

procedure DrawGUI(var player1 : Player1Stats; player2 : Player2Stats);
var p : Panel;

begin
	LoadResourceBundle('BattleBundle.txt');
	p := LoadPanel('BattleInterface.txt');
	ShowPanel(p);
	GUISetBackgroundColor(ColorBlue);
	GUISetForegroundColor(ColorWhite);
	LabelSetText(p,'PlayerStrength',  'Strength: ' + IntToStr(Player1.Strength)); //Sets GUI to show current player stats
	LabelSetText(p,'PlayerIntelligence',  'Intelligence: ' + IntToStr(Player1.Intelligence)); //Sets GUI to show current player stats
	LabelSetText(p,'PlayerSpeed',  'Speed: ' + IntToStr(Player1.Speed)); //Sets GUI to show current player stats
	LabelSetText(p,'PlayerWisdom',  'Wisdom: ' + IntToStr(Player1.Wisdom)); //Sets GUI to show current player stats
	LabelSetText(p,'PlayerDexterity',  'Dexterity: ' + IntToStr(Player1.Dexterity)); //Sets GUI to show current player stats 
end;

procedure GameOver(); //gameover screen

begin
	FadeMusicOut(100);
	LoadMusic('GameOver.mp3' );
    FadeMusicIn('GameOver.mp3', 100);
	repeat
		ProcessEvents(); 
		ReleaseAllPanels();
		DrawBitmap('GameOverScreen', 0, 0); 
		DrawInterface();
		RefreshScreen(60);
	until KeyTyped(vk_RETURN);
end;

procedure GameWin(); //victory screen

begin
	FadeMusicOut(100);
	LoadMusic('Victory.mp3' );
    FadeMusicIn('Victory.mp3', 100);
	repeat
		ProcessEvents(); 
		ReleaseAllPanels();
		DrawBitmap('VictoryScreen', 0, 0); 
		DrawInterface();
		RefreshScreen(60);
	until KeyTyped(vk_RETURN);
end;

function WaitForConnections(var MainMenuChange : Integer) : Connection; 
begin 
result := nil; 
while (result = nil) do 
	begin 
		AcceptTCPConnection(); 
		result := FetchConnection(); //loops until connection found
	end;  
	MainMenuChange := 1; //changes main menu background
end; 

function WaitToConnectToHost(var MainMenuChange : Integer) : Connection; 
begin 
result := nil; 
while (result = nil) do 
	begin
		result := CreateTCPConnection(RequiredIP, 4000); //loops until host found
	end;
	MainMenuChange := 1;
end; 

function ReadIP() : string;
begin
	DrawBitmap('IPSelectScreen', 0, 0);
	StartReadingText(ColorWhite, 32, LoadFont('VCR' , 29 ), 320, 412);
	while ReadingText() do
	begin
		ProcessEvents();
			DrawBitmap('IPSelectScreen', 0, 0);
		RefreshScreen(60);
	end;
	result := EndReadingText(); //sets result to player entered IP address to be used laer
end;

function SelectPeerType(var MainMenuChange : Integer) : Boolean; //selects whether user is host or joining

begin
	Result := false; 
	if KeyDown(vk_h) then
	begin
		CreateTCPHost(4000); 
        Result := True; 
        MultiplayerConnection := WaitForConnections(MainMenuChange);
        LoopLock := true;
	end;

	if KeyDown(vk_j) then 
	begin
		RequiredIP := ReadIP();
		Result := False; 
	    MultiplayerConnection := WaitToConnectToHost(MainMenuChange);
	    LoopLock := true;
	end;
end;

procedure SendStats(var player1 : Player1Stats);
begin
	SendTCPMessage(IntToStr(Player1.Strength), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.Intelligence), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.Speed), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.Wisdom), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.Dexterity), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.HP), MultiplayerConnection);
	SendTCPMessage(IntToStr(Player1.MP), MultiplayerConnection);
end;

procedure ReceiveStats(var player2 : player2stats);
begin
	Player2.Strength := StrToInt(ReadMessage(MultiplayerConnection));
	Player2.Intelligence := StrToInt(ReadMessage(MultiplayerConnection));
	Player2.Speed := StrToInt(ReadMessage(MultiplayerConnection));
	Player2.Wisdom := StrToInt(ReadMessage(MultiplayerConnection));
	Player2.Dexterity := StrToInt(ReadMessage(MultiplayerConnection));
	Player2.HP := 100;
	Player2.MP := 100;
end;

function CalculateMeleeSkillDamage(var skilltype : MeleeSkills; player : player1stats; x : integer) : Integer;
var strengthdec : real;
	dexdec : real;

begin
	strengthdec := (player.strength / 10);
	dexdec := (player.Dexterity / 10);
	result := round(skilltype[x].SkillPower * (2 + strengthdec) + (1 + dexdec)); //series of calculations dependant on player stats and skill power
end;

function CalculateMagicSkillDamage(var skilltype : MagicSkills; player : player1stats; x : integer) : Integer;
var wisdomdex : real;
	intdex : real;

begin
	wisdomdex := (player.wisdom / 10);
	intdex := (player.Intelligence / 10);
	result := round(skilltype[x].SkillPower * (2 + intdex) + (1 + wisdomdex));
end;

function CalculateRangedSkillDamage(var  skilltype : RangedSkills; player : player1stats; x : integer) : Integer;
var strengthdec : real;
	dexdec : real;

begin
	strengthdec := (player.strength / 10);
	dexdec := (player.Dexterity / 10);
	result := round(skilltype[x].SkillPower * (2 + dexdec) + (1 + strengthdec));
end;

function CalculateSelfSkillDamage(var skilltype : SelfSkills; player : player1stats; x : integer) : Integer;
begin
	result := skilltype[x].SkillPower * rnd(3);
end;

function CalculateSkillBuff(var skilltype : BuffSkills; x : integer) : Integer;
begin
	result := round(skilltype[x].SkillPower / 10);
end;

procedure P1MeleeAttackAnimation(var player1 : player1stats; player2 : Player2Stats);
var Player1Melee : Sprite;
	Player2Sprite : Sprite;

begin
    Player2Sprite := CreateSprite(BitmapNamed('Player2Idle') , AnimationScriptNamed('p1idle'));
	SpriteStartAnimation(Player2Sprite ,'start2' );
	SpriteSetX(Player2Sprite , 492 );
    SpriteSetY(Player2Sprite , 380 );
	
	Player1Melee := CreateSprite(BitmapNamed('Player1Attack') , AnimationScriptNamed('p1attack'));
	SpriteStartAnimation(Player1Melee ,'start' );
	SpriteSetX(Player1Melee , 140 );
    SpriteSetY(Player1Melee , 360 );

    repeat
    	ClearScreen(ColorWhite);
		DrawSprite(Player1Melee);
		DrawSprite(Player2Sprite);
		DrawText('HP: ' + IntToStr(Player1.HP), ColorBlue, LoadFont('VCR' , 29 ), 143, 339);
		DrawText('HP: ' + IntToStr(Player2.HP), ColorBlue, LoadFont('VCR' , 29 ), 480, 339);
		DrawInterface();
		UpdateInterface();
		RefreshScreen(60);
		UpdateSprite(Player1Melee );
		UpdateSprite(Player2Sprite);
		ProcessEvents(); 
	until SpriteCurrentCell(Player1Melee) = 12;
end;

procedure P2MeleeAttackAnimation(var player1 : player1stats; player2 : Player2Stats);
var Player2Melee : Sprite;
	Player1Sprite : Sprite;

begin
	Player1Sprite := CreateSprite(BitmapNamed('Player1Idle') , AnimationScriptNamed('p1idle'));
	SpriteStartAnimation(Player1Sprite ,'start2' );
	SpriteSetX(Player1Sprite , 140 );
    SpriteSetY(Player1Sprite , 380 );

    Player2Melee := CreateSprite(BitmapNamed('Player2Attack') , AnimationScriptNamed('p2attack'));
	SpriteStartAnimation(Player2Melee ,'start' );
	SpriteSetX(Player2Melee , 492 );
    SpriteSetY(Player2Melee , 360 );

    repeat
   		ClearScreen(ColorWhite);
   		DrawSprite(Player1Sprite);
		DrawSprite(Player2Melee);
		DrawText('HP: ' + IntToStr(Player1.HP), ColorBlue, LoadFont('VCR' , 29 ), 143, 339);
		DrawText('HP: ' + IntToStr(Player2.HP), ColorBlue, LoadFont('VCR' , 29 ), 480, 339);
		DrawInterface();
		UpdateInterface();
		RefreshScreen(60);
		UpdateSprite(Player2Melee );
		UpdateSprite(Player1Sprite );
		ProcessEvents(); 
	until SpriteCurrentCell(Player2Melee) = 12; //waits until animation is over to end
end;

procedure Battle(var player : player1stats; var player2 : Player2Stats; player1idle : sprite; player2idle : sprite);
var MeleePanel : panel;
	MagicPanel : panel;
	RangedPanel	: panel;
	SelfPanel : panel; 
	BuffPanel : panel;
	attackpanel : panel;
	battlepanel : panel;
	BattlePhaseOver : boolean;
	PanelState : integer;
	HideState : integer = 0;
	SkillLock : integer;
	Melee : MeleeSkills;
	Magic : MagicSkills;
	Ranged : RangedSkills;
	Self : SelfSkills;   
	Buff : BuffSkills;
	DamageDealt : Integer;
	DamageReceived : Integer;
	TurnLock : Integer;
	TurnOver : Integer;
	BuffType : integer;
	IgnoreDamage : integer;
	click : SoundEffect;
	P1Lock : integer;
	P2Lock : integer;

begin
Melee[0].SkillPower := 14;
Melee[1].SkillPower := 12;
Magic[0].SkillPower := 10; 
Magic[1].SkillPower := 13;
Magic[2].SkillPower := 16;
Ranged[0].SkillPower := 14;
Ranged[1].SkillPower := 11;
Self[0].SkillPower := 10;
Buff[0].SkillPower := 20;
Buff[1].SkillPower := 20;
Buff[2].SkillPower := 20;
Buff[3].SkillPower := 20; 

LoadResourceBundle('AttackBundle.txt'); //loads in resources
attackpanel := LoadPanel('AttackInterface.txt'); //loads in panel data from files
battlepanel := LoadPanel('BattleInterface.txt'); //loads in panel data from files
MeleePanel := LoadPanel('MeleePanel.txt'); //loads in panel data from files
RangedPanel := LoadPanel('RangedPanel.txt'); //loads in panel data from files
MagicPanel := LoadPanel('MagicPanel.txt'); //loads in panel data from files
SelfPanel := LoadPanel('SelfPanel.txt'); //loads in panel data from files
BuffPanel := LoadPanel('BuffPanel.txt'); //loads in panel data from files

Click := LoadSoundEffect('GUI.OGG'); //loads sound effect
ShowPanel(attackpanel);
BattlePhaseOver := false;
PanelState := 0;
DrawInterface();
UpdateInterface();
RefreshScreen();
TurnLock := 0;
DamageDealt := 0;
DamageReceived := 0;
TurnOver := 0;
BuffType := 0;
IgnoreDamage := 0;
ClearMessageQueue(MultiplayerConnection);
P1Lock := 0;
P2Lock := 0;

SpriteStartAnimation(player1idle ,'start2' );
SpriteSetX(player1idle , 140 );
SpriteSetY(player1idle , 380 );
SpriteStartAnimation(player2idle ,'start2' );
SpriteSetX(player2idle , 492 );
SpriteSetY(player2idle , 380 );

	repeat
		ProcessEvents();
		ClearScreen(ColorWhite);
		DrawText('HP: ' + IntToStr(Player.HP), ColorBlue, LoadFont('VCR' , 29 ), 143, 339); //draws player 1 HP to screen
		DrawText('HP: ' + IntToStr(Player2.HP), ColorBlue, LoadFont('VCR' , 29 ), 480, 339); //draws player 2 HP to screen
		DrawSprite(player1idle );
		DrawSprite(player2idle );
		if TCPMessageReceived() = true then //checks for surrender
		begin
			Victory := StrToInt(ReadMessage(MultiplayerConnection));
			PanelState := 1;
		end; 		
		if (RegionClickedId() = 'MeleeButton') and (TurnLock = 0) then //brings up Melee panel
			begin
				HidePanel(RangedPanel);
				HidePanel(MagicPanel);
				HidePanel(SelfPanel);
				HidePanel(BuffPanel);
				ShowPanel(MeleePanel);
				repeat 
					ProcessEvents();
					if (RegionClickedId() = 'SlashButton') then //calculates Slash damage
					begin
						DamageDealt := CalculateMeleeSkillDamage(melee, player, 0);
					end;

					if (RegionClickedId() = 'PunchButton') then //calculates Punch damage
					begin
						DamageDealt := CalculateMeleeSkillDamage(melee,player, 1);
					end;
					DrawInterface();
					UpdateInterface();
					RefreshScreen();
				until DamageDealt <> 0; //waits for damage to be calculated
				if DamageDealt <> 0 then //if damage is calculated proceed
				begin
					TurnLock := 1;
					SendTCPMessage(IntToStr(DamageDealt), MultiplayerConnection); //send damage dealt to opponent
					repeat
						if TCPMessageReceived() = true then //check to see if damage has been received
							begin
								DamageReceived := StrToInt(ReadMessage(MultiplayerConnection)); //store damage received from opponents damage dealt
							end;
					until DamageReceived <> 0; //waits untill opponents damage has been received
					if DamageReceived <> 0 then
					begin
						if (player.speed > player2.speed) and (P1lock = 0) then //has the player with the higher speed stat attack first
						begin
							P1MeleeAttackAnimation(player, player2);
							p2lock := 1;
						end;
						if (player2.speed > player.speed) and (P2lock = 0) then
						begin
							P2MeleeAttackAnimation(player, player2);
							p1lock := 1;
						end;
						if (player.speed < player2.speed) and (P1lock = 1) then
						begin
							P1MeleeAttackAnimation(player, player2);	
						end;
						if (player2.speed < player.speed) and (P2lock = 1) then
						begin
							P2MeleeAttackAnimation(player, player2);
						end;
						player.HP := player.HP - DamageReceived; //calculates new HP
						SendTCPMessage(IntToStr(player.hp), MultiplayerConnection); //sends opponent current HP
						delay(100);
						if TCPMessageReceived() = true then
							begin
								player2.hp := StrToInt(ReadMessage(MultiplayerConnection)); //stores opponents new HP
							end;
						TurnOver := 1;
						HidePanel(MeleePanel);
					end;
				end;
			end;
		if (RegionClickedId() = 'MagicPanel') and (TurnLock = 0) then
			begin
				PlaySoundEffect(Click);
				HidePanel(RangedPanel);
				HidePanel(MeleePanel);
				HidePanel(SelfPanel);
				HidePanel(BuffPanel);
				ShowPanel(MagicPanel);
				repeat
				ProcessEvents();
					if (RegionClickedId() = 'FireballButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateMagicSkillDamage(magic, player, 0);
					end;
					if (RegionClickedId() = 'LightningButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateMagicSkillDamage(magic, player, 1);
					end;
					if (RegionClickedId() = 'IceButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateMagicSkillDamage(magic, player, 2);
					end;
					DrawInterface();
					UpdateInterface();
					RefreshScreen();
				until DamageDealt <> 0;
				if DamageDealt <> 0 then
				begin
					TurnLock := 1;
					SendTCPMessage(IntToStr(DamageDealt), MultiplayerConnection);
					repeat
						if TCPMessageReceived() = true then
							begin
								DamageReceived := StrToInt(ReadMessage(MultiplayerConnection));
							end;
					until DamageReceived <> 0;
					if DamageReceived <> 0 then
					begin
						if (player.speed > player2.speed) and (P1lock = 0) then
						begin
							P1MeleeAttackAnimation(player, player2);
							p2lock := 1;
						end;
						if (player2.speed > player.speed) and (P2lock = 0) then
						begin
							P2MeleeAttackAnimation(player, player2);
							p1lock := 1;
						end;
						if (player.speed < player2.speed) and (P1lock = 1) then
						begin
							P1MeleeAttackAnimation(player, player2);	
						end;
						if (player2.speed < player.speed) and (P2lock = 1) then
						begin
							P2MeleeAttackAnimation(player, player2);
						end;
						player.HP := player.HP - DamageReceived;
						TurnOver := 1;
						SendTCPMessage(IntToStr(player.hp), MultiplayerConnection);
						delay(100);
						if TCPMessageReceived() = true then
							begin
								player2.hp := StrToInt(ReadMessage(MultiplayerConnection));
							end;
						TurnOver := 1;
						HidePanel(MagicPanel);
					end;
				end;
			end;
		if (RegionClickedId() = 'RangedPanel') and (TurnLock = 0) then
			begin
			PlaySoundEffect(Click);
			ProcessEvents();
				HidePanel(MeleePanel);
				HidePanel(MagicPanel);
				HidePanel(SelfPanel);
				HidePanel(BuffPanel);
				ShowPanel(RangedPanel);
				repeat
				ProcessEvents();
					if (RegionClickedId() = 'ShootButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateRangedSkillDamage(ranged, player, 0);
					end;
					if (RegionClickedId() = 'StoneButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateRangedSkillDamage(ranged, player, 1);
					end;
					DrawInterface();
					UpdateInterface();
					RefreshScreen();
				until DamageDealt <> 0;
				if DamageDealt <> 0 then
				begin
					TurnLock := 1;
					SendTCPMessage(IntToStr(DamageDealt), MultiplayerConnection);
					repeat
						if TCPMessageReceived() = true then
							begin
								DamageReceived := StrToInt(ReadMessage(MultiplayerConnection));
							end;
					until DamageReceived <> 0;	
					if DamageReceived <> 0 then
					begin
					if (player.speed > player2.speed) and (P1lock = 0) then
						begin
							P1MeleeAttackAnimation(player, player2);
							p2lock := 1;
						end;
						if (player2.speed > player.speed) and (P2lock = 0) then
						begin
							P2MeleeAttackAnimation(player, player2);
							p1lock := 1;
						end;
						if (player.speed < player2.speed) and (P1lock = 1) then
						begin
							P1MeleeAttackAnimation(player, player2);	
						end;
						if (player2.speed < player.speed) and (P2lock = 1) then
						begin
							P2MeleeAttackAnimation(player, player2);
						end;
						player.HP := player.HP - DamageReceived;
						SendTCPMessage(IntToStr(player.hp), MultiplayerConnection);
						delay(100);
						if TCPMessageReceived() = true then
							begin
								player2.hp := StrToInt(ReadMessage(MultiplayerConnection));
							end;
						TurnOver := 1;
						HidePanel(RangedPanel);
					end;
				end;
			end;
		if (RegionClickedId() = 'SelfPanel') and (TurnLock = 0) then
			begin
			PlaySoundEffect(Click);
			ProcessEvents();
				HidePanel(RangedPanel);
				HidePanel(MagicPanel);
				HidePanel(MeleePanel);
				HidePanel(BuffPanel);
				ShowPanel(SelfPanel);
				repeat
				ProcessEvents();
					if (RegionClickedId() = 'HealButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateSelfSkillDamage(self, player, 0);
						IgnoreDamage := 1;
					end;
					DrawInterface();
					UpdateInterface();
					RefreshScreen();
				until DamageDealt <> 0;
				if DamageDealt <> 0 then
				begin
					TurnLock := 1;
					SendTCPMessage(IntToStr(IgnoreDamage), MultiplayerConnection);
					repeat
						if TCPMessageReceived() = true then
							begin
								DamageReceived := StrToInt(ReadMessage(MultiplayerConnection));
							end;
					until DamageReceived <> 0;
					if DamageReceived <> 0 then
					begin
					if (player.speed > player2.speed) and (P1lock = 0) then
						begin
							P1MeleeAttackAnimation(player, player2);
							p2lock := 1;
						end;
						if (player2.speed > player.speed) and (P2lock = 0) then
						begin
							P2MeleeAttackAnimation(player, player2);
							p1lock := 1;
						end;
						if (player.speed < player2.speed) and (P1lock = 1) then
						begin
							P1MeleeAttackAnimation(player, player2);	
						end;
						if (player2.speed < player.speed) and (P2lock = 1) then
						begin
							P2MeleeAttackAnimation(player, player2);
						end;
						player.HP := player.HP + DamageDealt;
						player.HP := player.HP - DamageReceived;
						SendTCPMessage(IntToStr(player.hp), MultiplayerConnection);
						delay(100);
						if TCPMessageReceived() = true then
							begin
								player2.hp := StrToInt(ReadMessage(MultiplayerConnection));
							end;
						TurnOver := 1;
						HidePanel(SelfPanel);
					end;
				end;
			end;
		if (RegionClickedId() = 'BuffPanel') and (TurnLock = 0) then
			begin
			PlaySoundEffect(Click);
			ProcessEvents();
				HidePanel(RangedPanel);
				HidePanel(MagicPanel);
				HidePanel(SelfPanel);
				HidePanel(MeleePanel);
				ShowPanel(BuffPanel);
				repeat
				ProcessEvents();
					if (RegionClickedId() = 'MeditateButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateSkillBuff(buff, 0);
						BuffType := 1;
						IgnoreDamage := 1;
					end;
					if (RegionClickedId() = 'GuardButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateSkillBuff(buff, 1);
						BuffType := 2;
						IgnoreDamage := 1;
					end;
					if (RegionClickedId() = 'PrayButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateSkillBuff(buff, 2);
						BuffType := 3;
						IgnoreDamage := 1;
					end;
					if (RegionClickedId() = 'AdrenalineButton') then
					begin
						PlaySoundEffect(Click);
						DamageDealt := CalculateSkillBuff(buff, 3);
						BuffType := 4;
						IgnoreDamage := 1;
					end;
					DrawInterface();
					UpdateInterface();
					RefreshScreen();
				until DamageDealt <> 0;
				if DamageDealt <> 0 then
				begin
					TurnLock := 1;
					SendTCPMessage(IntToStr(IgnoreDamage), MultiplayerConnection);
					repeat
						if TCPMessageReceived() = true then
							begin
								DamageReceived := StrToInt(ReadMessage(MultiplayerConnection));
							end;
					until DamageReceived <> 0;
					if DamageReceived <> 0 then
					begin
					if (player.speed > player2.speed) and (P1lock = 0) then
						begin
							P1MeleeAttackAnimation(player, player2);
							p2lock := 1;
						end;
						if (player2.speed > player.speed) and (P2lock = 0) then
						begin
							P2MeleeAttackAnimation(player, player2);
							p1lock := 1;
						end;
						if (player.speed < player2.speed) and (P1lock = 1) then
						begin
							P1MeleeAttackAnimation(player, player2);	
						end;
						if (player2.speed < player.speed) and (P2lock = 1) then
						begin
							P2MeleeAttackAnimation(player, player2);
						end;
						player.HP := player.HP - DamageReceived;
						if BuffType = 1 then
						begin
							player.wisdom := player.wisdom + DamageDealt;
						end;
						if BuffType = 2 then
						begin
							player.speed := player.speed + DamageDealt;
						end;
						if BuffType = 3 then
						begin
							player.Intelligence := player.Intelligence + DamageDealt;
						end;
						if BuffType = 4 then
						begin
							player.strength := player.strength + DamageDealt;
						end;
						SendTCPMessage(IntToStr(player.hp), MultiplayerConnection);
						delay(100);
						if TCPMessageReceived() = true then
							begin
								player2.hp := StrToInt(ReadMessage(MultiplayerConnection));
							end;
						TurnOver := 1;
						HidePanel(BuffPanel);
					end;
				end;
			end;
			If DamageReceived = 1 then
			begin
				player.hp := player.hp + 1; //ignores damage from self and buff
			end;
			If IgnoreDamage = 1 then
			begin
				player2.hp := player2.hp + 1; //ignores damage from self and buff
			end;
			DrawInterface();
			UpdateInterface();
			RefreshScreen(60);
			UpdateSprite(Player1Idle);
			UpdateSprite(Player2Idle);
	until (PanelState = 1) or (TurnOver = 1);
	HidePanel(attackpanel);
	HidePanel(RangedPanel);
	HidePanel(MagicPanel);
	HidePanel(SelfPanel);
	HidePanel(MeleePanel);
	HidePanel(BuffPanel);
	DrawGUI(player, player2);
	ClearMessageQueue(MultiplayerConnection);
	If player.speed > player2.speed then //player with higher speed stat is delayed to ensure player with slower speed stat calculates loss first
	begin
		delay(100);
	end;
	If Loss = 1 then
	begin
		GameOver();
	end;
	If Victory = 2 then
	begin
		GameWin();
	end;
end;

procedure MainGame(var player1 : Player1Stats);
var Player2 : Player2Stats;
	GameOverCheck : boolean = false;
	GameOverLock : boolean = false;
	p2 : panel;
	Click : SoundEffect;
	Player1Sprite : Sprite;
	Player2Sprite : Sprite;

begin
	LoadResourceBundle('AnimationBundle.txt' ); //loads animation scripts and bitmaps
	LoadMusic('Battle.mp3' );
    Click := LoadSoundEffect('GUI.OGG'); //loads sound effect file to be played
	LoadResources();
	SendStats(player1); //sends player1 stats to player2
	Delay(2000);
	if TCPMessageReceived() = true then //receives player2 stats and stores them
	begin
		ReceiveStats(player2);
		ClearMessageQueue(MultiplayerConnection);
	end;
	DrawBitmap('Background', 0, 0);
	while (player1.speed = player2.speed) do  //if player speed stats are equal, randomize them
	begin
		player1.speed := rnd(10);
		player2.speed := rnd(10);
	end;

	DrawGUI(player1, player2);

	Player1Sprite := CreateSprite(BitmapNamed('Player1Idle') , AnimationScriptNamed('p1idle'));//creates sprites
	SpriteStartAnimation(Player1Sprite ,'start2' );//begins sprite animation based on file provided
	SpriteSetX(Player1Sprite , 140 );//sets sprite posistions
    SpriteSetY(Player1Sprite , 380 );//sets sprite posistions

    Player2Sprite := CreateSprite(BitmapNamed('Player2Idle') , AnimationScriptNamed('p2idle'));//creates sprites
	SpriteStartAnimation(Player2Sprite ,'start2' );//begins sprite animation based on file provided
	SpriteSetX(Player2Sprite , 492 );//sets sprite posistions
    SpriteSetY(Player2Sprite , 380 );//sets sprite posistions

	FadeMusicIn('Battle.mp3', 500);
    SetMusicVolume(2);
	repeat
		ClearScreen(ColorWhite);	
		DrawSprite(Player1Sprite ); //draws player character
		DrawSprite(Player2Sprite ); //draws player character
		if TCPMessageReceived() = true then //checks for surrender
		begin
			Victory := StrToInt(ReadMessage(MultiplayerConnection));
			GameOverLock := true;
		end;

		if (Player1.HP <= 0) and (gameoverlock = false) then //checks for player HP being less than 0
		begin
			Loss := 1;
			Victory := 0;
        	SendTCPMessage(IntToStr(2), MultiplayerConnection); //sends victory state to opponent
        	gameoverlock := true; //prevents loop
        	GameOverCheck := true; //exits battle loop
		end;
		
		if (RegionClickedId() = 'SurrenderButton') and (gameoverlock = false) then
		begin
			PlaySoundEffect(Click);
        	Loss := 1;
        	Victory := 0;
        	SendTCPMessage(IntToStr(2), MultiplayerConnection); //sends victory state to opponent
        	gameoverlock := true;
        	GameOverCheck := true;
		end;
		
		if RegionClickedId() = 'AttackButton' then
		begin
			PlaySoundEffect(Click);
			Battle(player1, player2, Player1Sprite, Player2Sprite); //enters battle state
		end;
		DrawInterface();
		UpdateInterface();
		UpdateSprite(Player1Sprite );
		UpdateSprite(Player2Sprite );
			RefreshScreen(60);
		ProcessEvents(); 
	until (GameOverCheck = true) or (Victory = 2); //exits main game function when one player loses
		If Loss = 1 then
		begin
			GameOver();
		end;
		If Victory = 2 then
		begin
			GameWin();
		end;
end;

procedure MainMenu();
var Player1 : Player1Stats;
	IsHost : Boolean = false;
	MainMenuChange : Integer = 0;
	Handshake1 : integer = 0;
	Handshake2 : integer = 0;

begin
	LoadMusic('MainMenu.mp3' ); //Loads in a music file to be called later
    PlayMusic('MainMenu.mp3', 10); //Plays previously loaded music files with the name specified
    SetMusicVolume(7);
	LoopLock := false; //Implements a lock to prevent looping
	Player1.Strength := Rnd(10); //Randomizes player stats 
	while Player1.Strength = (0) or (1) do 
	begin
		Player1.Strength := Rnd(10);
	end;
	Player1.Intelligence := Rnd(10); //Randomizes player stats
	while Player1.Intelligence = (0) or (1) do
	begin
		Player1.Intelligence := Rnd(10);
	end;
	Player1.Speed := Rnd(10); //Randomizes player stats
	while Player1.Speed = (0) or (1) do
	begin
		Player1.Speed := Rnd(10);
	end;
	Player1.Wisdom := Rnd(10); //Randomizes player stats
	while Player1.Wisdom = (0) or (1) do
	begin
		Player1.Wisdom := Rnd(10);
	end;
	Player1.Dexterity := Rnd(10); //Randomizes player stats
	while Player1.Dexterity = (0) or (1) do
	begin
		Player1.Dexterity := Rnd(10);
	end;
	Player1.HP := 100;
	Player1.MP := 100;
	DrawBitmap('MainMenuBackground', 0, 0); //draws mainmenu 
	repeat
		ProcessEvents(); 
		if LoopLock = false then
		begin
			IsHost := SelectPeerType(MainMenuChange);
		end;
		if MainMenuChange = 1 then
		begin
			DrawBitmap('MainMenuBackground2', 0, 0);
		end;
		if KeyDown(vk_RETURN) and (MainMenuChange = 1) then
		begin
			Handshake1 := 1;
			SendTCPMessage(IntToStr(1), MultiplayerConnection);
		end;
		if TCPMessageReceived() = true then
		begin
			Handshake2 := StrToInt(ReadMessage(MultiplayerConnection));
		end;
		DrawInterface();
		RefreshScreen(60);
	until (Handshake1 = 1) and (Handshake2 = 1); //When both players have clicked enter the code continues
	FadeMusicOut(3000); //Music fades out 
	ClearMessageQueue(MultiplayerConnection); //Clears any messages in the queue
	delay(1500);
	MainGame(player1); //Calls main game function
end;

procedure Main();
begin
	OpenAudio();
 	OpenGraphicsWindow('Custom RPG', 800, 600);
 	LoadDefaultColors();
 	LoadResources(); //Loads resources such as bitmaps that are used later 
	MainMenu(); //Calls the main menu which then allows the user to start the game																 				
    ReleaseAllResources();	
end;

begin
  Main();
end.
