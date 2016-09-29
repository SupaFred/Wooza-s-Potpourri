local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
local TableRemove = table.remove
local pairs = pairs;
local ipairs = ipairs;
local Plugin = Plugin;

Plugin.HasConfig = true;
Plugin.ConfigName = "AdvertsLas.json";

Plugin.PrintNextAdvert = nil; -- This will be set to a function in Initialise.


-- Recursive function that does a deep traversal of the adverts.
local function parseAdverts(group, adverts, default)
	local messages = {};

	local template = {
		pr = adverts.PrefixR or default.pr;
		pg = adverts.PrefixG or default.pg;
		pb = adverts.PrefixB or default.pg;
		r = adverts.R or default.r;
		g = adverts.G or default.g;
		b = adverts.B or default.b;
		prefix = adverts.Prefix or default.prefix;
	};
	if group then
		template.group = {
			parent = default.group;
			name = group;
		};
	else
		template.group = default.group;
	end

	adverts.Messages = adverts.Messages or {};
	for _, v in ipairs(adverts.Messages) do
		local message = {
			prefix = template.prefix;
			pr = template.pr;
			pg = template.pg;
			pb = template.pb;
			r = template.r;
			g = template.g;
			b = template.b;
			message = v;
		}
		table.insert(messages, message);
	end

	adverts.Nested = adverts.Nested or {};
	for k, v in pairs(adverts.Nested) do
		local nested = parseAdverts(k, v, template);
		for _, v in ipairs(nested) do
			table.insert(messages, v);
		end
	end

	return messages;
end

function Plugin:Initialise()

	Shared.RegisterNetworkMessage("ADVERTS_LAS_ADVERT", {
		pr = "integer (0 to 255)";
		pg = "integer (0 to 255)";
		pb = "integer (0 to 255)";
		r = "integer (0 to 255)";
		r = "integer (0 to 255)";
		b = "integer (0 to 255)";
		prefix = StringMessage;
		message = StringMessage;
	});

	local globalName = self.Config.GlobalName or "All";

	local adverts = parseAdverts(globalName, self.Config.Adverts, {
		prefix = "",
		pr = 255,
		pg = 255,
		pb = 255,
		r = 255,
		g = 255,
		b = 255,
	});

	local len = #adverts;

	local randomiseOrder = self.Config.RandomiseOrder;
	local interval = self.Config.Interval;

	local msg_id_func;
	local msg_id = 0;

	if randomiseOrder then
		msg_id_func = function()
			if msg_id == len then
				TableQuickShuffle(adverts);
				msg_id = 0;
			end
		end
	else
		msg_id_func = function()
			msg_id = msg_id % len;
		end
	end

	self.PrintNextAdvert = function()
		msg_id_func();
		msg_id = msg_id + 1;

		local msg = adverts[msg_id];

		Shine:NotifyDualColour(nil,
			msg.pr,	msg.pg,	msg.pb,	msg.prefix,
			msg.r,	msg.g,	msg.b,	msg.message
		);

		Server.SendNetworkMessage("ADVERTS_LAS_ADVERT", msg, true);
	end

	self:SimpleTimer(self.Config.Interval, self.PrintNextAdvert);

	self:BindCommand("sh_print_next_advert", "PrintNextAdvert", Plugin.PrintNextAdvert, true, true);

	self.Enabled = true;

	return true;
end
