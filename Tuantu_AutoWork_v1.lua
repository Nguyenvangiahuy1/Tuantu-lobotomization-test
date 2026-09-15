-- Tuantu's Lobotomization - Auto Work v1
-- Adaptive Auto Work controller. This v1 avoids guessing private remotes.
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LP=Players.LocalPlayer

local CFG={Enabled=false,ScanInterval=2.0,InteractionDistance=80,Debug=true}
local WORKS={"Instinct","Insight","Attachment","Repression"}
local SCORE={["VERY HIGH"]=5,["HIGH"]=4,["NORMAL"]=3,["LOW"]=2,["VERY LOW"]=1}

local PREFERENCE_DB={
 ["Subject 1"]={
  [1]={Instinct="LOW",Insight="NORMAL",Attachment="VERY HIGH",Repression="VERY LOW"},
  [2]={Instinct="LOW",Insight="NORMAL",Attachment="VERY HIGH",Repression="VERY LOW"},
  [3]={Instinct="LOW",Insight="NORMAL",Attachment="VERY HIGH",Repression="VERY LOW"},
  [4]={Instinct="LOW",Insight="NORMAL",Attachment="VERY HIGH",Repression="VERY LOW"},
  [5]={Instinct="LOW",Insight="NORMAL",Attachment="VERY HIGH",Repression="VERY LOW"},
 },
 ["Dignity"]={
  [1]={Instinct="HIGH",Insight="LOW",Attachment="LOW",Repression="LOW"},
  [2]={Instinct="NORMAL",Insight="LOW",Attachment="LOW",Repression="NORMAL"},
  [3]={Instinct="LOW",Insight="LOW",Attachment="LOW",Repression="HIGH"},
  [4]={Instinct="LOW",Insight="LOW",Attachment="LOW",Repression="HIGH"},
  [5]={Instinct="LOW",Insight="LOW",Attachment="LOW",Repression="VERY HIGH"},
 },
 ["The Influence"]={
  [1]={Instinct="VERY LOW",Insight="VERY HIGH",Attachment="VERY LOW",Repression="VERY LOW"},
  [2]={Instinct="VERY LOW",Insight="VERY HIGH",Attachment="VERY LOW",Repression="VERY LOW"},
  [3]={Instinct="VERY LOW",Insight="VERY HIGH",Attachment="VERY LOW",Repression="VERY LOW"},
  [4]={Instinct="VERY LOW",Insight="VERY HIGH",Attachment="VERY LOW",Repression="VERY LOW"},
  [5]={Instinct="VERY LOW",Insight="VERY HIGH",Attachment="VERY LOW",Repression="VERY LOW"},
 },
}

local state={lastTarget=nil,lastWork=nil,unknown={}}

local function log(...)
 if CFG.Debug then print("[Tuantu AutoWork]",...) end
end
local function compact(s) return string.lower(tostring(s or "")):gsub("[%s_%-%[%]%(%)]","") end
local function root()
 local c=LP.Character
 return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
local function getTier()
 local c=LP.Character
 for _,obj in ipairs({LP,c}) do
  if obj then
   for _,n in ipairs({"AgentTier","Tier","AgentLevel","StatLevel","Level","Rank"}) do
    local a=obj:GetAttribute(n); local v=tonumber(a)
    if v and v>=1 and v<=5 then return math.floor(v) end
    local x=obj:FindFirstChild(n)
    if x and x:IsA("IntValue") then
     v=tonumber(x.Value)
     if v and v>=1 and v<=5 then return math.floor(v) end
    end
   end
  end
 end
 return 1
end
local function displayName(inst)
 return tostring(inst:GetAttribute("Abnormality") or inst:GetAttribute("AbnormalityName") or inst:GetAttribute("Name") or inst.Name)
end
local function looksLike(inst)
 local s=compact(displayName(inst))
 return s:find("abnormal") or s:find("qliphoth") or s:find("containment") or inst:FindFirstChild("QliphothCounter") or inst:FindFirstChild("Work")
end
local function partOf(inst)
 return inst:IsA("BasePart") and inst or inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart",true)
end
local function distance(part)
 local r=root()
 return r and part and (r.Position-part.Position).Magnitude or math.huge
end
local function chooseWork(name,tier)
 local row=PREFERENCE_DB[name]; if not row then return nil end
 local p=row[tier] or row[1]; local best,bestScore
 for _,w in ipairs(WORKS) do
  local s=SCORE[p[w] or "NORMAL"] or 3
  if not bestScore or s>bestScore then best,bestScore=w,s end
 end
 return best,bestScore
end
local function nearestInteraction(target)
 local b,bd
 for _,d in ipairs(target:GetDescendants()) do
  if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
   local q=d.Parent
   while q and not q:IsA("BasePart") and q~=target do q=q.Parent end
   local dd=distance(q)
   if dd<(bd or math.huge) then b,bd=d,dd end
  end
 end
 return b
end
local function activate(obj)
 if not obj then return false end
 if obj:IsA("ProximityPrompt") and typeof(fireproximityprompt)=="function" then return pcall(fireproximityprompt,obj) end
 if obj:IsA("ClickDetector") and typeof(fireclickdetector)=="function" then return pcall(fireclickdetector,obj) end
 return false
end
local function scanOnce()
 if not CFG.Enabled then return end
 local tier=getTier(); local nearest,nd
 for _,container in ipairs({Workspace,ReplicatedStorage}) do
  for _,inst in ipairs(container:GetDescendants()) do
   if looksLike(inst) then
    local d=distance(partOf(inst))
    if d<=CFG.InteractionDistance and d<(nd or math.huge) then nearest,nd=inst,d end
   end
  end
 end
 if not nearest then log("No nearby Abnormality/containment candidate found."); return end
 local name=displayName(nearest); local work,score=chooseWork(name,tier)
 state.lastTarget=name; state.lastWork=work
 if not work then
  if not state.unknown[name] then state.unknown[name]=true; warn("[Tuantu AutoWork] Unknown Abnormality:",name) end
  return
 end
 log(("Target=%s | Tier=%d | Work=%s | Score=%s | Distance=%.1f"):format(name,tier,work,tostring(score),nd))
 local interaction=nearestInteraction(nearest)
 if interaction then
  log("Interaction:",interaction:GetFullName(),"fired:",activate(interaction))
 else
  log("No ProximityPrompt/ClickDetector. Work Remote/UI hook still needs game-specific mapping.")
 end
end

getgenv().TuantuAutoWork={
 Config=CFG,Preferences=PREFERENCE_DB,State=state,
 Start=function() CFG.Enabled=true end,
 Stop=function() CFG.Enabled=false end,
 Scan=scanOnce,
 SetDebug=function(v) CFG.Debug=v==true end,
 AddPreference=function(name,tier,values)
  if type(name)~="string" or type(values)~="table" then return false end
  tier=math.clamp(tonumber(tier) or 1,1,5)
  PREFERENCE_DB[name]=PREFERENCE_DB[name] or {}; PREFERENCE_DB[name][tier]=values; return true
 end
}
task.spawn(function()
 log("Ready. Use getgenv().TuantuAutoWork.Start()")
 while task.wait(CFG.ScanInterval) do pcall(scanOnce) end
end)
