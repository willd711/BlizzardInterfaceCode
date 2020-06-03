local Minimap =
{
	Name = "Minimap",
	Type = "System",
	Namespace = "C_Minimap",

	Functions =
	{
		{
			Name = "GetDrawGroundTextures",
			Type = "Function",

			Returns =
			{
				{ Name = "draw", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "GetViewRadius",
			Type = "Function",

			Returns =
			{
				{ Name = "yards", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetDrawGroundTextures",
			Type = "Function",

			Arguments =
			{
				{ Name = "draw", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "ShouldUseHybridMinimap",
			Type = "Function",

			Returns =
			{
				{ Name = "shouldUse", Type = "bool", Nilable = false },
			},
		},
	},

	Events =
	{
		{
			Name = "MinimapPing",
			Type = "Event",
			LiteralName = "MINIMAP_PING",
			Payload =
			{
				{ Name = "unitTarget", Type = "string", Nilable = false },
				{ Name = "y", Type = "number", Nilable = false },
				{ Name = "x", Type = "number", Nilable = false },
			},
		},
		{
			Name = "MinimapUpdateTracking",
			Type = "Event",
			LiteralName = "MINIMAP_UPDATE_TRACKING",
		},
		{
			Name = "MinimapUpdateZoom",
			Type = "Event",
			LiteralName = "MINIMAP_UPDATE_ZOOM",
		},
	},

	Tables =
	{
	},
};

APIDocumentation:AddDocumentationTable(Minimap);