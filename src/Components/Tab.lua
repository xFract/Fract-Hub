local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local Components = Root.Components

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = 0,
	TabCount = 0,
}

local COLUMN_GAP = 8
local COLUMN_BREAKPOINT = 600

local function bindCanvasSize(ScrollFrame, Layout)
	Creator.AddSignal(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 2)
	end)
end

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:GetCurrentTabPos()
	local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
	local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y

	return TabPos - TabHolderPos
end

function TabModule:New(Title, Icon, Parent)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
	}

	if Library:GetIcon(Icon) then
		Icon = Library:GetIcon(Icon)
	end

	if Icon == "" or nil then
		Icon = nil
	end

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = Icon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Text = Title,
			RichText = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0,
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			),
			TextSize = 12,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 8, 0.5, 0),
			BackgroundTransparency = 1,
			Image = Icon and Icon or nil,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
	})

	Tab.ContainerFrame = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Window.ContainerHolder,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = false,
		ScrollBarThickness = 0,
	}, {
		New("UIPadding", {
			PaddingRight = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
		}),
	})

	local SingleLayout = New("UIListLayout", {
		Padding = UDim.new(0, COLUMN_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local LeftLayout = New("UIListLayout", {
		Padding = UDim.new(0, COLUMN_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local RightLayout = New("UIListLayout", {
		Padding = UDim.new(0, COLUMN_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.SingleScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = Tab.ContainerFrame,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		SingleLayout,
	})

	Tab.LeftScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(0.5, -(COLUMN_GAP / 2), 1, 0),
		BackgroundTransparency = 1,
		Parent = Tab.ContainerFrame,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		LeftLayout,
	})

	Tab.RightScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(0.5, -(COLUMN_GAP / 2), 1, 0),
		Position = UDim2.new(0.5, (COLUMN_GAP / 2), 0, 0),
		BackgroundTransparency = 1,
		Parent = Tab.ContainerFrame,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		RightLayout,
	})

	bindCanvasSize(Tab.SingleScrollFrame, SingleLayout)
	bindCanvasSize(Tab.LeftScrollFrame, LeftLayout)
	bindCanvasSize(Tab.RightScrollFrame, RightLayout)

	Tab.Sections = {}

	function Tab:RelayoutSections()
		local contentWidth = Tab.ContainerFrame.AbsoluteSize.X - 11
		if contentWidth <= 0 then
			return
		end

		local isCompact = contentWidth < COLUMN_BREAKPOINT
		Tab.SingleScrollFrame.Visible = isCompact
		Tab.LeftScrollFrame.Visible = not isCompact
		Tab.RightScrollFrame.Visible = not isCompact

		local singleOrder = 0
		local leftOrder = 0
		local rightOrder = 0
		local leftHeight = 0
		local rightHeight = 0

		for _, sectionData in ipairs(Tab.Sections) do
			local sectionRoot = sectionData.Root
			local sectionHeight = sectionRoot.AbsoluteSize.Y > 0 and sectionRoot.AbsoluteSize.Y or sectionRoot.Size.Y.Offset

			if isCompact then
				singleOrder = singleOrder + 1
				sectionRoot.Parent = Tab.SingleScrollFrame
				sectionRoot.Size = UDim2.new(1, 0, 0, sectionRoot.Size.Y.Offset)
				sectionRoot.LayoutOrder = singleOrder
				sectionData.ApiSection.ScrollFrame = Tab.SingleScrollFrame
			else
				if leftHeight <= rightHeight then
					leftOrder = leftOrder + 1
					sectionRoot.Parent = Tab.LeftScrollFrame
					sectionRoot.Size = UDim2.new(1, 0, 0, sectionRoot.Size.Y.Offset)
					sectionRoot.LayoutOrder = leftOrder
					sectionData.ApiSection.ScrollFrame = Tab.LeftScrollFrame
					leftHeight = leftHeight + sectionHeight + COLUMN_GAP
				else
					rightOrder = rightOrder + 1
					sectionRoot.Parent = Tab.RightScrollFrame
					sectionRoot.Size = UDim2.new(1, 0, 0, sectionRoot.Size.Y.Offset)
					sectionRoot.LayoutOrder = rightOrder
					sectionData.ApiSection.ScrollFrame = Tab.RightScrollFrame
					rightHeight = rightHeight + sectionHeight + COLUMN_GAP
				end
			end
		end
	end

	Creator.AddSignal(Tab.ContainerFrame:GetPropertyChangedSignal("AbsoluteSize"), function()
		Tab:RelayoutSections()
	end)

	Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(1, Tab.Frame, "BackgroundTransparency")

	Creator.AddSignal(Tab.Frame.MouseEnter, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseLeave, function()
		Tab.SetTransparency(Tab.Selected and 0.89 or 1)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
		Tab.SetTransparency(0.92)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	Tab.Container = Tab.SingleScrollFrame
	Tab.ScrollFrame = Tab.SingleScrollFrame

	function Tab:AddSection(SectionTitle)
		local Section = { Type = "Section" }

		local SectionFrame = require(Components.Section)(SectionTitle, Tab.SingleScrollFrame)
		Section.Container = SectionFrame.Container
		Section.Root = SectionFrame.Root
		Section.ScrollFrame = Tab.SingleScrollFrame

		table.insert(Tab.Sections, {
			Root = SectionFrame.Root,
			ApiSection = Section,
		})

		Creator.AddSignal(SectionFrame.Root:GetPropertyChangedSignal("AbsoluteSize"), function()
			Tab:RelayoutSections()
		end)

		Tab:RelayoutSections()

		setmetatable(Section, Elements)
		return Section
	end

	setmetatable(Tab, Elements)
	return Tab
end

function TabModule:SelectTab(Tab)
	local Window = TabModule.Window

	TabModule.SelectedTab = Tab

	for _, TabObject in next, TabModule.Tabs do
		TabObject.SetTransparency(1)
		TabObject.Selected = false
	end
	TabModule.Tabs[Tab].SetTransparency(0.89)
	TabModule.Tabs[Tab].Selected = true

	Window.TabDisplay.Text = TabModule.Tabs[Tab].Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim
		
		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))
		task.wait(0.12)
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))
		task.wait(0.12)
		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

return TabModule
