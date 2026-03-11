local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New

return function(Title, Parent)
	local Section = {}

	Section.Layout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
	})

	Section.Container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 32), -- Push down below title and padding
		BackgroundTransparency = 1,
	}, {
		Section.Layout,
	})

	Section.Root = New("Frame", {
		BackgroundTransparency = 0, -- Solid background for the card
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 7,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "Element", -- Use Element or Dialog color for the card background
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("UIStroke", {
			Color = Color3.fromRGB(40, 45, 55), -- Example stroke, will use ThemeTag
			Thickness = 1,
			Transparency = 0,
			ThemeTag = {
				Color = "ElementBorder",
			},
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		New("TextLabel", {
			RichText = true,
			Text = Title,
			TextTransparency = 0,
			FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			TextSize = 14, -- Slightly smaller than the default 18
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromOffset(0, 0), -- Positioned at the top of the padding
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "SubText", -- Or Text, depending on preference
			},
		}),
		Section.Container,
	})

	Creator.AddSignal(Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Section.Container.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y)
		-- Calculate total height: PaddingTop + TitleHeight + Spacing + ContentSize + PaddingBottom
		Section.Root.Size = UDim2.new(1, 0, 0, 12 + 18 + 14 + Section.Layout.AbsoluteContentSize.Y + 12)
	end)
	return Section
end
