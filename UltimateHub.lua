-- Ultimate Hub v1.0 Minified - Made by Anos
local uis=game:GetService("UserInputService")local rs=game:GetService("RunService")local plr=game.Players.LocalPlayer;local mouse=plr:GetMouse()local tween=game:GetService("TweenService")local cam=workspace.CurrentCamera
-- Loading Screen
local screen=Instance.new("ScreenGui",game:GetService("CoreGui"))
local frame=Instance.new("Frame",screen)
frame.Size=UDim2.new(0,400,0,150)
frame.Position=UDim2.new(0.5,-200,0.5,-75)
frame.BackgroundColor3=Color3.fromRGB(20,20,20)
frame.BorderSizePixel=0
frame.AnchorPoint=Vector2.new(0.5,0.5)
local txt=Instance.new("TextLabel",frame)
txt.Size=UDim2.new(1,0,1,0)
txt.Text="Loading Anos' Ultimate Hub..."
txt.TextColor3=Color3.fromRGB(255,255,255)
txt.BackgroundTransparency=1
txt.Font=Enum.Font.SourceSansBold
txt.TextScaled=true
wait(2)
screen:Destroy()
-- Main GUI
local hub=Instance.new("ScreenGui",game:GetService("CoreGui"))
local main=Instance.new("Frame",hub)
main.Size=UDim2.new(0,500,0,400)
main.Position=UDim2.new(0.5,-250,0.5,-200)
main.BackgroundColor3=Color3.fromRGB(30,30,30)
main.AnchorPoint=Vector2.new(0.5,0.5)
main.BorderSizePixel=0
local UIList=Instance.new("UIListLayout",main)
UIList.FillDirection=Enum.FillDirection.Horizontal
UIList.HorizontalAlignment=Enum.HorizontalAlignment.Center
UIList.Padding=UDim.new(0,5)
-- Tabs
local tabs={"Movement","Combat","Teleports","Fun","Misc","Credits"}
local frames={}
for i,v in pairs(tabs)do
	local btn=Instance.new("TextButton",main)
	btn.Text=v
	btn.Size=UDim2.new(0,80,0,30)
	btn.BackgroundColor3=Color3.fromHSV(tick()%10/10,1,1)
	btn.TextColor3=Color3.new(1,1,1)
	btn.MouseButton1Click:Connect(function()
		for _,f in pairs(frames)do f.Visible=false end
		if frames[v]then frames[v].Visible=true end
	end)
	local f=Instance.new("Frame",main)
	f.Size=UDim2.new(1,-10,1,-50)
	f.Position=UDim2.new(0,5,0,40)
	f.Visible=false
	f.BackgroundColor3=Color3.fromRGB(35,35,35)
	frames[v]=f
end
frames["Movement"].Visible=true
-- Rainbow UI effect
rs.RenderStepped:Connect(function()
	for _,b in pairs(main:GetChildren())do
		if b:IsA("TextButton")then
			b.BackgroundColor3=Color3.fromHSV(tick()%10/10,1,1)
		end
	end
end)
-- Example Features
-- Movement
local wsBtn=Instance.new("TextButton",frames["Movement"])
wsBtn.Size=UDim2.new(0,150,0,40)
wsBtn.Position=UDim2.new(0,10,0,10)
wsBtn.Text="WalkSpeed +50"
wsBtn.MouseButton1Click:Connect(function()
	plr.Character.Humanoid.WalkSpeed=50
end)
local jpBtn=Instance.new("TextButton",frames["Movement"])
jpBtn.Size=UDim2.new(0,150,0,40)
jpBtn.Position=UDim2.new(0,10,0,60)
jpBtn.Text="JumpPower +100"
jpBtn.MouseButton1Click:Connect(function()
	plr.Character.Humanoid.JumpPower=100
end)
-- Combat (Example)
local dmgBtn=Instance.new("TextButton",frames["Combat"])
dmgBtn.Size=UDim2.new(0,150,0,40)
dmgBtn.Position=UDim2.new(0,10,0,10)
dmgBtn.Text="Infinite Damage"
dmgBtn.MouseButton1Click:Connect(function()
	print("Damage set to max (placeholder)")
end)
-- Teleports (Example)
local tpBtn=Instance.new("TextButton",frames["Teleports"])
tpBtn.Size=UDim2.new(0,150,0,40)
tpBtn.Position=UDim2.new(0,10,0,10)
tpBtn.Text="Teleport to Spawn"
tpBtn.MouseButton1Click:Connect(function()
	plr.Character.HumanoidRootPart.CFrame=CFrame.new(Vector3.new(0,10,0))
end)
-- Fun
local flyBtn=Instance.new("TextButton",frames["Fun"])
flyBtn.Size=UDim2.new(0,150,0,40)
flyBtn.Position=UDim2.new(0,10,0,10)
flyBtn.Text="Fly (Toggle)"
local flying=false
flyBtn.MouseButton1Click:Connect(function()
	flying=not flying
	local hrp=plr.Character.HumanoidRootPart
	if flying then
		local body=Instance.new("BodyVelocity",hrp)
		body.MaxForce=Vector3.new(1e5,1e5,1e5)
		rs.RenderStepped:Connect(function()
			if flying then
				body.Velocity=Vector3.new(0,0,0)
			else body:Destroy() end
		end)
	end
end)
-- Misc
local espBtn=Instance.new("TextButton",frames["Misc"])
espBtn.Size=UDim2.new(0,150,0,40)
espBtn.Position=UDim2.new(0,10,0,10)
espBtn.Text="Enable ESP"
espBtn.MouseButton1Click:Connect(function()
	for _,p in pairs(game.Players:GetPlayers())do
		if p~=plr and p.Character and not p.Character:FindFirstChild("ESP")then
			local box=Instance.new("BoxHandleAdornment",p.Character)
			box.Adornee=p.Character:FindFirstChild("HumanoidRootPart")
			box.Size=Vector3.new(2,3,1)
			box.Color=BrickColor.new("Bright red")
			box.AlwaysOnTop=true
			box.Name="ESP"
		end
	end
end)
-- Credits
local creditsLbl=Instance.new("TextLabel",frames["Credits"])
creditsLbl.Size=UDim2.new(1,0,1,0)
creditsLbl.Text="Made by Anos\nEnjoy the Ultimate Hub!"
creditsLbl.TextColor3=Color3.new(1,1,1)
creditsLbl.BackgroundTransparency=1
creditsLbl.Font=Enum.Font.SourceSansBold
creditsLbl.TextScaled=true
